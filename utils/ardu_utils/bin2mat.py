#!/usr/bin/env python3
"""
Convert ArduPilot .BIN log file to MATLAB .mat file.
Captures all message types and numeric fields.

Usage: ./bin_to_mat.py <logfile.BIN>
Output: <logfile.BIN>.mat
"""

from pymavlink import mavutil
import scipy.io
import numpy as np
import pandas as pd
import sys
import os

# ── Command line argument ──────────────────────────────────────────────────
if len(sys.argv) != 2:
    print("Usage: ./bin_to_mat.py <logfile.BIN>")
    sys.exit(1)

input_file = sys.argv[1]
if not os.path.isfile(input_file):
    print(f"Error: file not found: {input_file}")
    sys.exit(1)

output_file = input_file + ".mat"

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

# ── Parse log ─────────────────────────────────────────────────────────────
print(f"Reading: {input_file}")
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

# ── Convert to DataFrames ──────────────────────────────────────────────────
frames = {}
for msg_type, messages in data.items():
    if messages:
        frames[msg_type] = pd.DataFrame(messages)

# ── Build MAT output ───────────────────────────────────────────────────────
mat_data = {}

for msg_type, df in frames.items():
    for col in df.columns:
        field_name = f"{msg_type}_{col}"
        try:
            mat_data[field_name] = df[col].to_numpy(dtype=float)
        except (ValueError, TypeError):
            pass  # skip non-numeric fields

# ── PWM percent effort conversions ────────────────────────────────────────
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

# ── Save ───────────────────────────────────────────────────────────────────
scipy.io.savemat(output_file, mat_data)
print(f"\nSaved: {output_file}")
print(f"Total fields exported: {len(mat_data)}")