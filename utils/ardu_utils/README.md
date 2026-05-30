# ardu_utils

Utilities for processing ArduPilot `.BIN` telemetry logs.

## Tools

| Script | Description |
|--------|-------------|
| `bin2mat.py` | Convert one or more `.BIN` logs to MATLAB `.mat` files |
| `bin_timespan.py` | Print the first/last UTC timestamp of each `.BIN` (CSV) |
| `bin_coursetime.py` | Measure waypoint-course elapsed time from each `.BIN` against a mission file (CSV, optional trajectory plots) |

---

## Python virtual environment setup

Do this once per machine (or whenever you clone the repo).

```bash
# 1. Create the virtual environment inside this directory
python3 -m venv .venv

# 2. Activate it
source .venv/bin/activate   # Linux / macOS
# .venv\Scripts\activate    # Windows

# 3. Install dependencies
pip install -r requirements.txt
```

To deactivate the environment when you're done:

```bash
deactivate
```

On subsequent sessions, just re-run step 2 to activate before using the scripts.

---

## Usage

Activate the virtual environment first, then run the script.

**Single file:**
```bash
python bin2mat.py /path/to/00000001.BIN
```

**Glob pattern (multiple files):**
```bash
python bin2mat.py '/path/to/logs/*.BIN'
```

Quoting the pattern is optional when the shell is in a directory with no matching files, but quoting is safer — it lets Python do the expansion and avoids the shell eating the wildcard.

**Output:** each input file produces a `<filename>.BIN_YYYYMMDD_HHMMSS.mat` in the same directory, where the timestamp is the earliest log timestamp in UTC.

---

## Output format

Each `.mat` file contains one variable per numeric field, named `{MSGTYPE}_{field}` — for example `GPS_Spd`, `RCOU_C3`, `IMU_GyrZ`. All timestamps are Unix/POSIX time (seconds since epoch), stored in `{MSGTYPE}_timestamp`.

The earliest timestamp found in the log is embedded in the output filename as `_YYYYMMDD_HHMMSS` (UTC), so files from different runs sort chronologically and cannot collide. Example: `00000001.BIN_20240315_143022.mat`.

Additional derived variables are added for common PWM channels:

| Variable | Description |
|----------|-------------|
| `RCOU_C1_pct_throttle` | Throttle output, 0–100 % |
| `RCOU_C3_pct_rudder` | Rudder output, −100 to +100 % |
| `RCIN_C1_pct_throttle` | Throttle input, 0–100 % |
| `RCIN_C3_pct_rudder` | Rudder input, −100 to +100 % |

---

## `bin_coursetime.py` — waypoint-course elapsed time

For the Lab 3 challenge course. Given a QGC WPL `.waypoints` mission file and one
or more `.BIN` logs, reports the elapsed time to run the course for each log.

**Timing definition**

- **start** — first instant the vehicle is within the acceptance radius of the
  first course waypoint (mission row 1; the home row 0 is ignored)
- **stop** — first instant at/after start that the vehicle is within the
  acceptance radius of the final course waypoint

The track is taken from `POS` messages (the EKF-fused lat/lon estimate, ~10× denser
than `GPS`). Elapsed time uses the `POS` boot clock, so it is a true duration and
needs no GPS/UTC fix. Lat/lon are projected to a local East/North (meters) tangent
plane about the mission's mean latitude.

**Acceptance radius** — by default the `WP_RADIUS` parameter logged in each `.BIN`
is used (falling back to 1.0 m if absent). Override for all files with `-r/--radius`.

**Usage:**
```bash
# single file
python bin_coursetime.py /path/to/00000038.BIN mission.waypoints

# folder (globs *.BIN) or quoted glob, with per-BIN trajectory plots
python bin_coursetime.py /path/to/logs/ mission.waypoints -p
python bin_coursetime.py '/path/to/logs/*.BIN' mission.waypoints -p

# force a fixed acceptance radius (ignore logged WP_RADIUS)
python bin_coursetime.py /path/to/logs/ mission.waypoints -r 2.0
```

**Output:** CSV on stdout (diagnostics go to stderr), one row per file:
```
filename,elapsed_hms,elapsed_seconds,radius_m,status
```
`status` is `ok` for a completed course, or `never_reached_wp1` /
`never_reached_final` / `no_track` / `read_error` when the criteria aren't met —
in which case the elapsed fields are zero-filled.

With `-p/--plot`, each `.BIN` also gets a `<logfile>.coursetime.png` showing the
East/North trajectory, the waypoints with dashed acceptance-radius circles, the
detected start (green ▲) and stop (red ▼) points, and the elapsed time.
