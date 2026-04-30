# ardu_utils

Utilities for processing ArduPilot `.BIN` telemetry logs.

## Tools

| Script | Description |
|--------|-------------|
| `bin2mat.py` | Convert one or more `.BIN` logs to MATLAB `.mat` files |

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
