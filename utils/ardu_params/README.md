# ArduRover Parameter Setup for USV Labs

This directory contains the ArduRover parameter files used in the USV lab experiments.

| File | Description |
|------|-------------|
| `ArduRoverV4.6.3_ReInstall_Default.param` | Factory defaults after a fresh firmware install |
| `2026_05_06_baseline_3.2.param` | Baseline configuration for USV lab experiments |

## How to Load Parameters

The simplest and most reliable method is to load the baseline `.param` file directly via Mission Planner or QGroundControl:

**Mission Planner:** Config → Full Parameter List → Load from file → select `2026_05_06_baseline_3.2.param` → Write Params

**QGroundControl:** Vehicle Setup → Parameters → Tools (top right) → Load from file → select file → restart vehicle if prompted

After loading, reboot the flight controller.

> **Note on calibration parameters:** The baseline `.param` file includes compass calibration offsets, IMU calibration values, and RC calibration trims that are specific to the vehicle it was calibrated on. When loading onto a different vehicle, you must re-run the compass calibration, accelerometer calibration, and RC calibration procedures after loading — those procedures will overwrite the vehicle-specific values from the file.

---

## What the Baseline Changes (Relative to Default)

The tables below document every meaningful functional change from the factory default. These are organized by subsystem. **Parameters set by calibration procedures are listed separately at the bottom** — do not set those manually.

### Vehicle Frame Type

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `FRAME_CLASS` | 1 | **2** | 1=Rover, 2=Boat. Must be set to 2 for USV operation. |

### CAN Bus and GPS

The USV uses a DroneCAN GPS connected over CAN bus. The default configuration uses a serial GPS.

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `CAN_P1_DRIVER` | 0 | **1** | Enable CAN port 1 driver |
| `CAN_P2_DRIVER` | 0 | **1** | Enable CAN port 2 driver |
| `GPS1_TYPE` | 1 | **9** | 1=serial GPS, 9=DroneCAN GPS |
| `GPS1_CAN_NODEID` | 0 | **124** | CAN node ID assigned to the GPS unit |

### Attitude and Rate Controller

These parameters tune the autopilot controllers for a boat hull (no brakes, high lateral G capability).

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `ATC_BRAKE` | 1 | **0** | Disable active braking (boats cannot brake) |
| `ATC_ACCEL_MAX` | 1 | **10** | Maximum lateral acceleration (m/s²); increase for boat dynamics |
| `ATC_TURN_MAX_G` | 0.6 | **10** | Maximum lateral G for turns; increase for boat |
| `ATC_STR_ACC_MAX` | 120 | **0** | Steering rate acceleration limit; 0 = unlimited |
| `ATC_STR_RAT_FF` | 0.2 | **0** | Steering rate feed-forward; set to 0 for USV |
| `PSC_VEL_P` | 1 | **6** | Position controller velocity P gain |
| `STICK_MIXING` | 0 | **1** | Allow pilot stick input to mix into auto modes |
| `ACRO_TURN_RATE` | 180 | **360** | Acro mode turn rate (deg/s) |

### Speed and Waypoint Navigation

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `CRUISE_SPEED` | 2 | **5** | Target cruise speed (m/s) in auto modes |
| `CRUISE_THROTTLE` | 50 | **0** | Cruise throttle (%); set to 0 when using speed controller |
| `WP_RADIUS` | 2 | **1** | Waypoint acceptance radius (m) |
| `AUTO_KICKSTART` | 0 | **2** | Auto-mode kickstart: 0=disabled, 2=triggered by throttle |

### Motor and Throttle

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `MOT_THR_MIN` | 0 | **20** | Minimum throttle (%) when armed and moving |
| `SERVO3_MIN` | 1100 | **1300** | Throttle servo minimum PWM (μs) |
| `SERVO3_MAX` | 1900 | **1670** | Throttle servo maximum PWM (μs) |

### Arming and Safety

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `BRD_SAFETY_DEFLT` | 1 | **0** | Hardware safety switch: 1=required on boot, 0=not required |

### Flight Modes

Mode switch is on RC channel 6. The baseline assigns two useful modes.

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `MODE_CH` | 8 | **6** | RC channel used for mode selection |
| `MODE1` | 0 | **10** | Mode for switch position 1: 0=Manual, 10=Auto |
| `MODE4` | 0 | **1** | Mode for switch position 4: 0=Manual, 1=Acro |

### Mission Behavior

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `MIS_DONE_BEHAVE` | 0 | **1** | Behavior when mission completes: 0=hold, 1=loiter |

### Compass Configuration

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `COMPASS_EXTERNAL` | 0 | **1** | 0=internal compass only, 1=use external compass |
| `COMPASS_USE3` | 1 | **0** | Disable third compass (not present) |

### RC Channel Configuration

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `RC1_REVERSED` | 0 | **1** | Reverse channel 1 (steering/roll) |
| `RC5_OPTION` | 0 | **153** | Assign function to RC5 switch (see ArduPilot RC option docs) |
| `RC7_OPTION` | 0 | **30** | Assign function to RC7 switch (see ArduPilot RC option docs) |

### Logging

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `LOG_DISARMED` | 0 | **1** | Log data even when disarmed |
| `LOG_FILE_DSRMROT` | 0 | **1** | Start a new log file each time the vehicle disarms |

### Telemetry Stream Rates (Serial Port 1 / Telem1)

These increase the data rate on the telemetry radio port for better real-time monitoring.

| Parameter | Default | Baseline | Notes |
|-----------|---------|----------|-------|
| `SR1_EXT_STAT` | 1 | **2** | Extended status stream rate (Hz) |
| `SR1_EXTRA1` | 1 | **4** | Extra1 stream rate (Hz) |
| `SR1_EXTRA2` | 1 | **4** | Extra2 stream rate (Hz) |
| `SR1_EXTRA3` | 1 | **2** | Extra3 stream rate (Hz) |
| `SR1_POSITION` | 1 | **2** | Position stream rate (Hz) |
| `SR1_RAW_SENS` | 1 | **2** | Raw sensor stream rate (Hz) |
| `SR1_RC_CHAN` | 1 | **2** | RC channel stream rate (Hz) |
| `GCS_PID_MASK` | 0 | **2** | Stream PID data to GCS (bitmask; 2=steering) |

---

## Parameters Set by Calibration Procedures (Do Not Set Manually)

The following parameters appear different between the default and baseline files because they are set automatically by calibration procedures. After loading the baseline `.param` file on a new vehicle, run the appropriate calibration wizard to update these for your specific hardware.

### Compass Calibration
Run the compass calibration wizard in Mission Planner or QGroundControl. It will set:
`COMPASS_DEC`, `COMPASS_OFS_X/Y/Z`, `COMPASS_OFS2_X/Y/Z`, `COMPASS_SCALE`, `COMPASS_SCALE2`, `COMPASS_DEV_ID`, `COMPASS_DEV_ID2`, `COMPASS_PRIO1_ID`, `COMPASS_PRIO2_ID`

### Accelerometer Calibration
Run the accelerometer calibration wizard. It will set:
`INS_ACCOFFS_X/Y/Z`, `INS_ACC2OFFS_X/Y/Z`, `INS_ACC3OFFS_X/Y/Z`, `INS_ACC1_CALTEMP`, `INS_ACC2_CALTEMP`, `INS_ACC3_CALTEMP`

### Gyro Calibration
Performed automatically on boot. It will set:
`INS_GYROFFS_X/Y/Z`, `INS_GYR2OFFS_X/Y/Z`, `INS_GYR3OFFS_X/Y/Z`, `INS_GYR1_CALTEMP`, `INS_GYR2_CALTEMP`, `INS_GYR3_CALTEMP`

### RC Calibration
Run the RC calibration wizard. It will set:
`RC2_MIN`, `RC2_TRIM`, `RC3_MAX`, `RC3_MIN`, `RC3_TRIM`, `RC5_MAX`, `RC5_MIN`, `RC5_TRIM`, `RC6_MAX`, `RC6_MIN`, `RC6_TRIM`, `RC7_MAX`, `RC7_MIN`, `RC7_TRIM`, `RC8_MAX`, `RC8_MIN`, `RC8_TRIM`, `RC9_MAX`, `RC9_MIN`, `RC9_TRIM`

### Barometer (Automatic)
`BARO1_GND_PRESS` and `BARO2_GND_PRESS` are updated on each boot and reflect local atmospheric pressure. They do not need to be set manually.

### Runtime Statistics (Ignore)
`STAT_BOOTCNT`, `STAT_FLTTIME`, `STAT_RUNTIME`, `MIS_TOTAL` — these track vehicle usage history and are not configuration parameters.
