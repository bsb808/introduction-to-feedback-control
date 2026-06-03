#!/usr/bin/env python3
"""
Measure waypoint-course elapsed time from one or more ArduPilot .BIN logs.

Given a QGC WPL waypoint mission file and one or more .BIN logs, this computes,
for each log, the elapsed time to run the course:

    start = first instant the vehicle is within the acceptance radius of the
            first course waypoint (mission row 1; the home row 0 is ignored)
    stop  = first instant at/after `start` that the vehicle is within the
            acceptance radius of the final course waypoint

The vehicle track is taken from POS messages (the EKF-fused lat/lon estimate,
~10x denser than GPS). Elapsed time uses the POS TimeUS clock, so it is a true
duration and needs no GPS/UTC fix.

Acceptance radius: by default the WP_RADIUS parameter logged in each BIN is used
(falling back to 1.0 m if absent). Override for all files with -r/--radius.

If a log never satisfies both conditions (no successful course), its elapsed
fields are filled with zeros and a status column explains why.

Environment: this script needs the ardu_utils virtualenv (pymavlink, and
matplotlib for -p). Activate it first, then run with plain `python`:
  cd utils/ardu_utils
  source .venv/bin/activate            # see README.md for one-time setup
  python bin_coursetime.py ...
Running ./bin_coursetime.py or system `python3` without activating will fail
with ModuleNotFoundError: No module named 'pymavlink'.

Usage:
  python bin_coursetime.py <logfile.BIN> <mission.waypoints>
  python bin_coursetime.py /path/to/folder <mission.waypoints>      # globs *.BIN
  python bin_coursetime.py '/path/to/*.BIN' <mission.waypoints>     # quote glob
  python bin_coursetime.py <input> <mission.waypoints> -p           # also plot
  python bin_coursetime.py <input> <mission.waypoints> -r 2.0       # fixed radius

Output: CSV on stdout, one row per file:
    filename,elapsed_hms,elapsed_seconds,start_utc,radius_m,status
Header is printed first. Diagnostics go to stderr. start_utc is the UTC
timestamp of the WP1-radius entry (derived via pymavlink from the log's
GPS lock); empty if no GPS lock or no successful course.

With -p/--plot, a PNG (<logfile>.coursetime.png) is written next to each BIN
showing the x/y (East/North) trajectory, the waypoints, a dashed acceptance-
radius circle around each, the detected start/stop points, and the elapsed time.

Worked examples (paths are illustrative; substitute your own):

  # Whole folder of logs against the AY26Q3 challenge course, with plots:
  source .venv/bin/activate   # see README.md for one-time setup
  python bin_coursetime.py \\
      ../../../data/2026_05_29_lab3_proto/2026_05_29_plans/logs/ \\
      ../../site/weeks/w10_lab_usv_waypoint/docs/challengecourse_ay26q3.waypoints \\
      -p

  # A single full run (prototype log 38 -> 00:05:42 against plan_1):
  python bin_coursetime.py -p ../../../data/2026_05_29_lab3_proto/2026_05_29_plans/logs/00000038.BIN ../../../data/2026_05_29_lab3_proto/2026_05_29_plans/plan_1.waypoints 

  # Capture the CSV to a file (stderr diagnostics still print to the terminal):
  python bin_coursetime.py <logs-folder> <mission.waypoints> > coursetimes.csv

  # Force a fixed acceptance radius, ignoring each log's WP_RADIUS:
  python bin_coursetime.py <logs-folder> <mission.waypoints> -r 2.0

Use cases:
  * Post-field grading of the Lab 3 challenge course — one CSV row of elapsed
    time per team .BIN, directly comparable across runs.
  * Cross-checking the scribe's stopwatch time against the log-derived time.
  * Generating the trajectory-vs-waypoints figure for the deliverable slide (-p).
  * Triaging a folder of logs to find which ones actually completed the course
    (status == ok) versus aborted/partial runs (never_reached_* / no_track).

Note: a log only reports a time against the mission it actually flew. Run a log
against the wrong .waypoints file and it will (correctly) report never_reached_wp1.
"""

from pymavlink import mavutil
import sys
import os
import glob
import csv
import argparse
import math


# WGS84 equatorial radius (m). A local equirectangular projection about the
# mission's mean latitude is accurate to well under a meter over a course this
# size, and distances are translation-invariant so the origin choice is moot.
EARTH_R = 6378137.0

# ArduPilot MAV_CMD values that place a physical navigation waypoint. Mission
# rows with other commands (jumps, DO_* actions) carry no position and are
# skipped when picking the first/last course waypoints.
NAV_CMDS = {16, 82}  # NAV_WAYPOINT, NAV_SPLINE_WAYPOINT

DEFAULT_RADIUS_M = 1.0


def parse_mission(path):
    """Parse a QGC WPL 110 .waypoints file.

    Returns a list of (seq, lat, lon) for navigable waypoints, in file order,
    with the home row (seq 0) excluded. Columns (tab-separated):
      seq cur frame cmd p1 p2 p3 p4 lat lon alt autocontinue
    """
    waypoints = []
    with open(path) as fh:
        lines = [ln.rstrip('\n') for ln in fh if ln.strip()]
    if not lines or not lines[0].startswith('QGC WPL'):
        raise ValueError(f"not a QGC WPL waypoint file: {path}")
    for ln in lines[1:]:
        cols = ln.split('\t')
        if len(cols) < 12:
            cols = ln.split()  # tolerate space-separated exports
        if len(cols) < 12:
            continue
        seq = int(cols[0])
        cmd = int(cols[3])
        lat = float(cols[8])
        lon = float(cols[9])
        if seq == 0:
            continue  # home / launch point — not part of the timed course
        if cmd not in NAV_CMDS:
            continue
        if lat == 0.0 and lon == 0.0:
            continue
        waypoints.append((seq, lat, lon))
    return waypoints


def make_projector(lat0, lon0):
    """Return f(lat, lon) -> (x_east_m, y_north_m) via equirectangular projection."""
    cos_lat0 = math.cos(math.radians(lat0))

    def project(lat, lon):
        x = EARTH_R * math.radians(lon - lon0) * cos_lat0
        y = EARTH_R * math.radians(lat - lat0)
        return x, y

    return project


def read_log(bin_path):
    """Read POS track, WP_RADIUS, and 'Reached waypoint #N' events.

    Returns (track, wp_radius, reached) where:
      track     list of (t_us, t_unix, lat, lon)
      wp_radius logged WP_RADIUS value (float), or None if absent
      reached   list of (t_unix, wp_num) from autopilot 'Reached waypoint
                #N' MSG events — the autopilot's authoritative call,
                which accepts perpendicular crossings in addition to
                radius entry (matters at speed, where the boat
                overshoots without dipping inside WP_RADIUS).

    t_unix is pymavlink's _timestamp; becomes valid UTC after the first
    GPS lock. GPS messages are included in the recv filter so the UTC
    mapping is established as soon as a fix appears.
    """
    mlog = mavutil.mavlink_connection(bin_path)
    track = []
    wp_radius = None
    reached = []
    while True:
        msg = mlog.recv_match(type=['POS', 'PARM', 'GPS', 'MSG'])
        if msg is None:
            break
        t = msg.get_type()
        if t == 'POS':
            track.append((msg.TimeUS, getattr(msg, '_timestamp', 0.0),
                          msg.Lat, msg.Lng))
        elif t == 'PARM':
            # Last logged value wins if a param is emitted more than once.
            if str(getattr(msg, 'Name', '')).strip() == 'WP_RADIUS':
                try:
                    wp_radius = float(msg.Value)
                except (ValueError, TypeError):
                    pass
        elif t == 'MSG':
            text = str(getattr(msg, 'Message', '')).strip()
            if text.startswith('Reached waypoint #'):
                try:
                    n = int(text.replace('Reached waypoint #', ''))
                    reached.append((getattr(msg, '_timestamp', 0.0), n))
                except ValueError:
                    pass
    return track, wp_radius, reached


def course_time(track, project, waypoints, radius_m, reached=None):
    """Compute the course timing for one track.

    Authoritative source is ArduPilot's own 'Reached waypoint #N' MSG
    events when present (see read_log's `reached`). The autopilot
    advances on radius entry *or* perpendicular crossing — important
    when the boat overshoots a waypoint at speed without dipping inside
    the strict radius. Falls back to a POS-radius check requiring
    in-order entry of every waypoint if no MSG events are available
    (older firmware or stripped logs).

    Returns a dict with keys:
      elapsed_s     float seconds (0.0 if unsuccessful)
      start_idx     index into track nearest the WP1-reach time
      stop_idx      index into track nearest the WPn-reach time
      start_t_unix  unix time of WP1 reach (or None)
      status        'ok' | 'no_track' | 'never_reached_wpN'
      source        'msg' (autopilot events) | 'pos' (POS-radius
                    fallback). Useful for explaining a result.
    """
    result = {'elapsed_s': 0.0, 'start_idx': None, 'stop_idx': None,
              'start_t_unix': None, 'status': 'no_track', 'source': None}
    if not track:
        return result

    # --- Preferred: MSG-event scoring ---
    if reached:
        t_at = {}                     # first reach time per WP number
        cursor = 1
        for t_unix, n in reached:
            if n == cursor and n not in t_at:
                t_at[n] = t_unix
                cursor += 1
                if cursor > len(waypoints):
                    break
        if 1 not in t_at:
            result['status'] = 'never_reached_wp1'
            result['source'] = 'msg'
            return result
        target_n = len(waypoints)
        if target_n not in t_at:
            # First missing WP in sequence after 1.
            missed = next(n for n in range(2, target_n + 1) if n not in t_at)
            result['status'] = f'never_reached_wp{missed}'
            result['source'] = 'msg'
            return result
        # Map t_unix to nearest track index for plot markers.
        def nearest_idx(t):
            best_i, best_d = 0, abs(track[0][1] - t)
            for i in range(1, len(track)):
                d = abs(track[i][1] - t)
                if d < best_d:
                    best_d, best_i = d, i
            return best_i
        start_idx = nearest_idx(t_at[1])
        stop_idx = nearest_idx(t_at[target_n])
        result.update(elapsed_s=t_at[target_n] - t_at[1],
                      start_idx=start_idx, stop_idx=stop_idx,
                      start_t_unix=t_at[1], status='ok', source='msg')
        return result

    # --- Fallback: POS-radius scoring (no MSG events) ---
    wp_xy = [project(lat, lon) for _, lat, lon in waypoints]
    r2 = radius_m * radius_m
    cursor = 0
    start_idx = None
    stop_idx = None
    for i, (_, _, lat, lon) in enumerate(track):
        if cursor >= len(wp_xy):
            break
        x, y = project(lat, lon)
        wx, wy = wp_xy[cursor]
        if (x - wx) ** 2 + (y - wy) ** 2 <= r2:
            if cursor == 0:
                start_idx = i
            cursor += 1
            if cursor == len(wp_xy):
                stop_idx = i
                break

    if start_idx is None:
        result['status'] = 'never_reached_wp1'
        result['source'] = 'pos'
        return result
    if stop_idx is None:
        result['status'] = f'never_reached_wp{cursor + 1}'
        result['source'] = 'pos'
        return result

    elapsed_s = (track[stop_idx][0] - track[start_idx][0]) / 1e6
    result.update(elapsed_s=elapsed_s, start_idx=start_idx,
                  stop_idx=stop_idx, start_t_unix=track[start_idx][1],
                  status='ok', source='pos')
    return result


def fmt_hms(seconds):
    """Format a non-negative duration in seconds as HH:MM:SS."""
    total = int(round(seconds))
    h, rem = divmod(total, 3600)
    m, s = divmod(rem, 60)
    return f"{h:02d}:{m:02d}:{s:02d}"


def fmt_utc(t_unix):
    """Format a unix timestamp as 'YYYY-MM-DD HH:MM:SS UTC' (empty if None/0)."""
    import datetime
    if not t_unix:
        return ''
    dt = datetime.datetime.fromtimestamp(t_unix, tz=datetime.timezone.utc)
    return dt.strftime('%Y-%m-%d %H:%M:%S UTC')


def plot_course(bin_path, track, project, waypoints, radius_m, result):
    """Write <bin_path>.coursetime.png showing trajectory, waypoints, radii."""
    import matplotlib
    matplotlib.use('Agg')  # headless: write file, no display
    import matplotlib.pyplot as plt
    from matplotlib.patches import Circle

    xs, ys = [], []
    for _, _, lat, lon in track:
        x, y = project(lat, lon)
        xs.append(x)
        ys.append(y)

    fig, ax = plt.subplots(figsize=(8, 8))
    ax.plot(xs, ys, '-', color='0.5', linewidth=0.8, label='trajectory', zorder=1)

    # Waypoints + acceptance-radius annotation circles.
    for n, (seq, lat, lon) in enumerate(waypoints, start=1):
        wx, wy = project(lat, lon)
        ax.add_patch(Circle((wx, wy), radius_m, fill=False, linestyle=':',
                            edgecolor='b', linewidth=1.0, zorder=2))
        ax.plot(wx, wy, 'o', color='b', markersize=2, zorder=3)
        ax.annotate(str(n), (wx, wy), textcoords='offset points',
                    xytext=(5, 5), fontsize=9, color='b')

    # Start / stop markers.
    if result['start_idx'] is not None:
        ax.plot(xs[result['start_idx']], ys[result['start_idx']], '^',
                color='green', markersize=11, label='start (WP1 radius)', zorder=4)
    if result['stop_idx'] is not None:
        ax.plot(xs[result['stop_idx']], ys[result['stop_idx']], 'v',
                color='red', markersize=11, label='stop (final WP radius)', zorder=4)

    ax.set_aspect('equal', adjustable='datalim')
    ax.set_xlabel('East (m)')
    ax.set_ylabel('North (m)')
    ax.grid(True, linestyle=':', alpha=0.5)
    ax.legend(loc='best', fontsize=9)

    name = os.path.basename(bin_path)
    if result['status'] == 'ok':
        
        subtitle = ( #f"elapsed {fmt_hms(result['elapsed_s'])} "
                    f"Elapsed time: {result['elapsed_s']:.2f} s   |   Accept. radius: {radius_m:g} m")
    else:
        subtitle = f"no successful course ({result['status']})   |   Accept. radius: {radius_m:g} m"
    ax.set_title(f"{name}\n{subtitle}", fontsize=11)

    out_path = bin_path + '.coursetime.png'
    fig.tight_layout()
    fig.savefig(out_path, dpi=150)
    plt.close(fig)
    return out_path


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
    parser = argparse.ArgumentParser(
        description='Measure waypoint-course elapsed time from ArduPilot .BIN logs.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__)
    parser.add_argument('bin_input',
                        help='a .BIN file, a folder (globs *.BIN), or a quoted glob')
    parser.add_argument('mission',
                        help='QGC WPL .waypoints mission file')
    parser.add_argument('-r', '--radius', type=float, default=None,
                        help='acceptance radius in meters; overrides the log WP_RADIUS '
                             f'(fallback {DEFAULT_RADIUS_M:g} m if neither given)')
    parser.add_argument('-p', '--plot', action='store_true',
                        help='write <logfile>.coursetime.png per BIN')
    args = parser.parse_args()

    try:
        waypoints = parse_mission(args.mission)
    except (OSError, ValueError) as e:
        print(f"Error: cannot read mission file: {e}", file=sys.stderr)
        sys.exit(1)
    if len(waypoints) < 2:
        print(f"Error: mission needs >= 2 course waypoints (got {len(waypoints)}) "
              f"after excluding home", file=sys.stderr)
        sys.exit(1)
    wp_first, wp_last = waypoints[0], waypoints[-1]
    print(f"Mission: {len(waypoints)} course waypoints (seq {wp_first[0]}..{wp_last[0]}); "
          f"timing WP{1} -> WP{len(waypoints)}", file=sys.stderr)

    # Project about the mean waypoint latitude to minimize distortion.
    lat0 = sum(w[1] for w in waypoints) / len(waypoints)
    lon0 = sum(w[2] for w in waypoints) / len(waypoints)
    project = make_projector(lat0, lon0)

    files = resolve_inputs(args.bin_input)
    if not files:
        print(f"Error: no .BIN files matched: {args.bin_input}", file=sys.stderr)
        sys.exit(1)

    writer = csv.writer(sys.stdout)
    writer.writerow(['filename', 'elapsed_hms', 'elapsed_seconds',
                     'start_utc', 'radius_m', 'status'])

    for f in files:
        if not os.path.isfile(f):
            print(f"Warning: skipping non-file: {f}", file=sys.stderr)
            continue
        #print(f"Reading: {f}", file=sys.stderr)
        try:
            track, log_radius, reached = read_log(f)
        except Exception as e:
            print(f"Warning: failed to read {f}: {e}", file=sys.stderr)
            writer.writerow([f, fmt_hms(0), '0.0', '', '', 'read_error'])
            continue

        # Radius precedence: CLI override > logged WP_RADIUS > default.
        if args.radius is not None:
            radius_m = args.radius
        elif log_radius is not None:
            radius_m = log_radius
        else:
            radius_m = DEFAULT_RADIUS_M
            print(f"  note: WP_RADIUS not in log; using default {DEFAULT_RADIUS_M:g} m",
                  file=sys.stderr)

        result = course_time(track, project, waypoints, radius_m,
                             reached=reached)
        if result['status'] == 'ok':
            print(f"  elapsed {fmt_hms(result['elapsed_s'])} "
                  f"({result['elapsed_s']:.1f} s), radius {radius_m:g} m", file=sys.stderr)
        else:
            print(f"  {result['status']} (radius {radius_m:g} m) -> zeros", file=sys.stderr)

        writer.writerow([f, fmt_hms(result['elapsed_s']),
                         f"{result['elapsed_s']:.1f}",
                         fmt_utc(result['start_t_unix']),
                         f"{radius_m:g}", result['status']])

        if args.plot:
            try:
                out = plot_course(f, track, project, waypoints, radius_m, result)
                print(f"  plot: {out}", file=sys.stderr)
            except Exception as e:
                print(f"  Warning: plot failed for {f}: {e}", file=sys.stderr)


if __name__ == '__main__':
    main()
