#!/usr/bin/env python3
"""
Print the first and last UTC timestamps of one or more ArduPilot .BIN logs.

Intended for matching log files to scribe notes — minute-level precision is
plenty. Speed trick: only iterate GPS messages, which carry real UTC time and
stream at ~5 Hz vs ~1 kHz for the full message mix (~200x fewer to parse).
First GPS timestamp → start; last GPS timestamp → stop.

Usage:
  ./bin_timespan.py <logfile.BIN>
  ./bin_timespan.py /path/to/folder           # auto-globs *.BIN inside
  ./bin_timespan.py '/path/to/data/*.BIN'     # quote to suppress shell glob

Output: CSV on stdout, one row per file:
    filename,start_utc,stop_utc
Header is printed first.
"""

from pymavlink import mavutil
import sys
import os
import glob
import csv
import datetime


# First plausible UTC timestamp ( > year 2001 ) — anything smaller is a
# boot-relative time logged before the GPS provided a real fix.
MIN_PLAUSIBLE_UTC = 1e9


def timespan(bin_path):
    """Return (start_unix, end_unix) of the first/last GPS-stamped message."""
    mlog = mavutil.mavlink_connection(bin_path)
    start = None
    end = None
    while True:
        msg = mlog.recv_match(type='GPS')
        if msg is None:
            break
        t = getattr(msg, '_timestamp', None)
        if not t or t < MIN_PLAUSIBLE_UTC:
            continue
        if start is None:
            start = t
        end = t
    return start, end


def fmt_utc(t_unix):
    if t_unix is None:
        return ''
    dt = datetime.datetime.fromtimestamp(t_unix, tz=datetime.timezone.utc)
    return dt.strftime('%Y-%m-%d %H:%M:%S UTC')


def resolve_inputs(pattern):
    """Accept a single .BIN, a directory (auto-globs *.BIN), or a glob."""
    if os.path.isdir(pattern):
        files = sorted(
            glob.glob(os.path.join(pattern, '*.BIN'))
            + glob.glob(os.path.join(pattern, '*.bin'))
        )
    else:
        files = sorted(glob.glob(pattern))
    return files


def main():
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    pattern = sys.argv[1]
    files = resolve_inputs(pattern)
    if not files:
        print(f"Error: no .BIN files matched: {pattern}", file=sys.stderr)
        sys.exit(1)

    rows = []
    for f in files:
        if not os.path.isfile(f):
            print(f"Warning: skipping non-file: {f}", file=sys.stderr)
            continue
        print(f"Reading: {f}", file=sys.stderr)
        try:
            start, end = timespan(f)
        except Exception as e:
            print(f"Warning: failed to read {f}: {e}", file=sys.stderr)
            continue
        rows.append((start, end, f))

    # Ascending by start time; files with no GPS-fixed start sort last.
    rows.sort(key=lambda r: (r[0] is None, r[0]))

    writer = csv.writer(sys.stdout)
    writer.writerow(['filename', 'start_utc', 'stop_utc'])
    for start, end, f in rows:
        writer.writerow([f, fmt_utc(start), fmt_utc(end)])


if __name__ == '__main__':
    main()
