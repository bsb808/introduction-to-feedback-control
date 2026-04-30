#!/usr/bin/env python3
"""
Convert ArduPilot .BIN log file(s) to MATLAB .mat files.
Captures all message types and numeric fields.

Usage:
  ./bin2mat.py <logfile.BIN>
  ./bin2mat.py /path/to/data/*.BIN
  ./bin2mat.py "/path/to/data/*.BIN"   # quoted to prevent shell expansion

Output: <logfile.BIN>.mat for each input file
"""

from pymavlink import mavutil
import scipy.io
import numpy as np
import pandas as pd
import sys
import os
import glob
import datetime

# ── PWM conversion helpers ─────────────────────────────────────────────────
PWM_MIN = 1000
PWM_MAX = 2000
PWM_MID = 1500

def pwm_to_pct(pwm):
    """Bidirectional: PWM 1000-2000 → -100 to +100% (rudder)"""
    return ((np.array(pwm) - PWM_MID) / (PWM_MAX - PWM_MID)) * 100

def pwm_to_pct_unidirectional(pwm):
    """Unidirectional: PWM 1000-2000 → 0 to 100% (throttle)"""
    return ((np.array(pwm) - PWM_MIN) / (PWM_MAX - PWM_MIN)) * 100


def convert(input_file):
    # ── Parse log ─────────────────────────────────────────────────────────
    print(f"\nReading: {input_file}")
    mlog = mavutil.mavlink_connection(input_file)

    data = {}

    while True:
        msg = mlog.recv_match()
        if msg is None:
            break
        msg_type = msg.get_type()
        if msg_type == 'BAD_DATA':
            continue
        if msg_type not in data:
            data[msg_type] = []
        d = msg.to_dict()
        d['timestamp'] = msg._timestamp
        data[msg_type].append(d)

    print(f"Found {len(data)} message types:")
    for msg_type, messages in sorted(data.items()):
        print(f"  {msg_type}: {len(messages)} records")

    # ── Convert to DataFrames ──────────────────────────────────────────────
    frames = {}
    for msg_type, messages in data.items():
        if messages:
            frames[msg_type] = pd.DataFrame(messages)

    # ── Build output filename with timestamp ───────────────────────────────
    min_ts = None
    for df in frames.values():
        if 'timestamp' in df.columns:
            ts = df['timestamp'].min()
            if min_ts is None or ts < min_ts:
                min_ts = ts

    if min_ts is not None:
        dt = datetime.datetime.utcfromtimestamp(min_ts)
        ts_str = dt.strftime('%Y%m%d_%H%M%S')
        print(f"First timestamp: {dt.strftime('%Y-%m-%d %H:%M:%S')} UTC")
        output_file = input_file + f"_{ts_str}.mat"
    else:
        output_file = input_file + ".mat"

    # ── Build MAT output ───────────────────────────────────────────────────
    mat_data = {}

    for msg_type, df in frames.items():
        for col in df.columns:
            field_name = f"{msg_type}_{col}"
            try:
                mat_data[field_name] = df[col].to_numpy(dtype=float)
            except (ValueError, TypeError):
                pass  # skip non-numeric fields

    # ── ArduPilot parameters (PARM messages) ──────────────────────────────
    # Saved as a struct: d.params.ATC_SPEED_P, d.params.ATC_SPEED_I, etc.
    if 'PARM' in frames:
        parm_df = frames['PARM']
        if 'Name' in parm_df.columns and 'Value' in parm_df.columns:
            parm_struct = {}
            for _, row in parm_df.iterrows():
                name = str(row['Name']).strip()
                if not name:
                    continue
                try:
                    # Use last logged value if a param appears more than once
                    parm_struct[name] = float(row['Value'])
                except (ValueError, TypeError):
                    pass
            mat_data['params'] = parm_struct
            print(f"Parameters saved: {len(parm_struct)}")

    # ── PWM percent effort conversions ────────────────────────────────────
    # Adjust channel numbers to match your vehicle wiring
    if 'RCOU' in frames:
        rcou = frames['RCOU']
        if 'C1' in rcou.columns:
            mat_data['RCOU_C1_pct_throttle'] = pwm_to_pct_unidirectional(rcou['C1'])
        if 'C3' in rcou.columns:
            mat_data['RCOU_C3_pct_rudder'] = pwm_to_pct(rcou['C2'])

    if 'RCIN' in frames:
        rcin = frames['RCIN']
        if 'C1' in rcin.columns:
            mat_data['RCIN_C1_pct_throttle'] = pwm_to_pct_unidirectional(rcin['C1'])
        if 'C3' in rcin.columns:
            mat_data['RCIN_C3_pct_rudder'] = pwm_to_pct(rcin['C2'])

    # ── Save ───────────────────────────────────────────────────────────────
    scipy.io.savemat(output_file, mat_data)
    print(f"Saved: {output_file}")
    print(f"Total fields exported: {len(mat_data)}")


# ── Command line argument ──────────────────────────────────────────────────
if len(sys.argv) != 2:
    print("Usage: ./bin2mat.py <logfile.BIN>")
    print("       ./bin2mat.py '/path/to/data/*.BIN'")
    sys.exit(1)

pattern = sys.argv[1]

# Expand glob pattern (handles both literal paths and wildcards)
input_files = sorted(glob.glob(pattern))

if not input_files:
    # Pattern matched nothing — treat as a literal path for a clear error message
    if '*' in pattern or '?' in pattern or '[' in pattern:
        print(f"Error: no files matched: {pattern}")
    else:
        print(f"Error: file not found: {pattern}")
    sys.exit(1)

errors = []
for f in input_files:
    if not os.path.isfile(f):
        print(f"Warning: skipping non-file: {f}")
        continue
    try:
        convert(f)
    except Exception as e:
        print(f"Error processing {f}: {e}")
        errors.append(f)

if errors:
    print(f"\n{len(errors)} file(s) failed: {errors}")
    sys.exit(1)

if len(input_files) > 1:
    print(f"\nDone: processed {len(input_files)} file(s).")
