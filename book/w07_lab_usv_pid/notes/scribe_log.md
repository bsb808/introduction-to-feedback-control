# Lab 2 Scribe Log — USV PID Control

**Date:** \_\_\_\_\_\_\_\_\_\_\_\_  
**Team:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  
**Vehicle:** \_\_\_\_\_\_\_\_\_\_\_\_  
**Pilot:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  **Planner:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_  **Scribe:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## Pre-Run Checklist

- [ ] Mode set to **ACRO** before every arming
- [ ] Parameter file saved in Mission Planner **before** arming (timestamp in filename)
- [ ] Scribe records time and log number at arming
- [ ] Same step fraction used across Run 1 and Run 2 for direct comparison
- [ ] Surge and yaw trials in **separate** log files (disarm between channels)

---

## Parameter Legend

All parameters viewed and set in Mission Planner (Config → Full Parameter List).

| Column | ArduPilot Parameter | Description |
|--------|--------------------|----|
| `SP_P` | `ATC_SPEED_P` | Surge speed proportional gain |
| `SP_I` | `ATC_SPEED_I` | Surge speed integral gain |
| `SP_D` | `ATC_SPEED_D` | Surge speed derivative gain |
| `SP_FF`| `ATC_SPEED_FF` | Surge speed feedforward |
| `A_MAX`| `ATC_ACCEL_MAX` | Speed cmd rate limit (m/s²); **0 = off** |
| `YR_P` | `ATC_STR_RAT_P` | Yaw-rate proportional gain |
| `YR_I` | `ATC_STR_RAT_I` | Yaw-rate integral gain |
| `YR_D` | `ATC_STR_RAT_D` | Yaw-rate derivative gain |
| `YR_FF`| `ATC_STR_RAT_FF` | Yaw-rate feedforward |
| `YA_MAX`| `ATC_STR_ACC_MAX` | Yaw-rate cmd rate limit (deg/s²); **0 = off** |

---

## Run Log

**One row per arming.** Save the param file in MP before each arm. Record the log number from the autopilot SD card (shown in MP HUD after arming).

| Run | Time (PDT) | ☐ ARM | ☐ ACRO | Log # | Trial | `SP_P` | `SP_I` | `SP_D` | `SP_FF` | `A_MAX` | `YR_P` | `YR_I` | `YR_D` | `YR_FF` | `YA_MAX` | Notes |
|:---:|:----------:|:-----:|:------:|:-----:|:-----:|-------:|-------:|-------:|--------:|--------:|-------:|-------:|-------:|--------:|---------:|-------|
| 1 | | ☐ | ☐ | | Surge | | | | | | — | — | — | — | — | |
| 2 | | ☐ | ☐ | | Yaw | — | — | — | — | — | | | | | | |
| 3 | | ☐ | ☐ | | Surge | | | | | | — | — | — | — | — | |
| 4 | | ☐ | ☐ | | Yaw | — | — | — | — | — | | | | | | |
| 5 | | ☐ | ☐ | | Surge | | | | | | — | — | — | — | — | |
| 6 | | ☐ | ☐ | | Yaw | — | — | — | — | — | | | | | | |
| 7 | | ☐ | ☐ | | Surge | | | | | | — | — | — | — | — | |
| 8 | | ☐ | ☐ | | Yaw | — | — | — | — | — | | | | | | |
| 9 | | ☐ | ☐ | | Surge | | | | | | — | — | — | — | — | |
| 10 | | ☐ | ☐ | | Yaw | — | — | — | — | — | | | | | | |
| 11 | | ☐ | ☐ | | | | | | | | | | | | | |
| 12 | | ☐ | ☐ | | | | | | | | | | | | | |

---

## Param File Record

List every param file saved, in order. Filename should include the time (e.g. `429261311_param_dump.param`).

| # | Filename | Notes on what changed |
|:-:|----------|-----------------------|
| 1 | | Baseline |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |

---

## General Notes

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
