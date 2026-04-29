# ArduRover PID Control — Reference Links

Key ArduPilot documentation pages for understanding the closed-loop control architecture used in Lab 2.

## Core Tuning Guides

- [Tuning Throttle and Speed](https://ardupilot.org/rover/docs/rover-tuning-throttle-and-speed.html) — Documents the surge speed PID (`ATC_SPEED_P/I/D/FF`) and acceleration limiting (`ATC_ACCEL_MAX`, `ATC_DECEL_MAX`); primary reference for Lab 2 speed controller parameters.

- [Tuning Steering Rate](https://ardupilot.org/rover/docs/rover-tuning-steering-rate.html) — Documents the yaw-rate PID (`ATC_STR_RAT_P/I/D/FF`) and calls this "the most important controller to tune"; primary reference for Lab 2 steering parameters.

## Control Architecture and Mode

- [ACRO Mode](https://ardupilot.org/rover/docs/acro-mode.html) — Describes the RC mode where the throttle stick commands speed and the steering stick commands turn rate through closed-loop PIDs; explicitly recommended as the best mode for tuning the steering rate controller.

- [Tuning Process Overview](https://ardupilot.org/rover/docs/rover-tuning-process.html) — Describes the recommended sequential tuning order from inner loops (speed, steering rate) outward to navigation; gives students the layered control hierarchy in plain language.

- [Navigation Tuning](https://ardupilot.org/rover/docs/rover-tuning-navigation.html) — Covers the outer position/velocity control loops (`PSC_VEL_*`, `PSC_POS_P`) that sit above the speed and steering rate PIDs; useful context for Lab 3 (waypoint race).

## Parameter Reference

- [Full Parameter List](https://ardupilot.org/rover/docs/parameters.html) — Comprehensive listing of all ArduRover parameters grouped by prefix (`ATC_SPEED_*`, `ATC_STR_*`, etc.); authoritative source for verifying parameter names and defaults before the lab.

## Notes

- The steering acceleration limiter (`ATC_STR_ACC_MAX`) may need to be set to 0 alongside `ATC_ACCEL_MAX` to allow a true step input to the steering rate controller — verify against V4.6.3 parameter documentation.
- All parameter names and defaults should be confirmed against **ArduRover V4.6.3 (3fc7011a)** before the lab.
