# ArduRover Speed and Steering ATC Parameters — Reference Notes

Reference for the `ATC_*` parameters that govern the closed-loop speed and yaw-rate controllers used in this course's USV labs (ACRO mode).

- **Authoritative parameter list (firmware version-tracked):** [ardupilot.org/rover/docs/parameters.html](https://ardupilot.org/rover/docs/parameters.html)
- **Source of truth for defaults / ranges / behavior:** [`libraries/APM_Control/AR_AttitudeControl.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp) on GitHub

Defaults below are taken from the `AR_AttitudeControl.cpp` source on `master`. Where our test vehicle (`42926_boat_tests_2801` parameter dump) differs from the source default, the vehicle value is shown as **Vehicle:**.

---

## Architecture overview

ACRO mode runs two independent PID loops, one per channel. Both share the same structure: a command **rate limiter** at the input, a **low-pass filter** on the error, a **PID** controller, and a **feed-forward** term that bypasses the PID and adds at the output.

![ATC PID architecture — speed and yaw-rate loops](images/atc_pid_architecture.svg)

*Source: [`images/atc_pid_architecture.drawio`](images/atc_pid_architecture.drawio) — edit in [diagrams.net](https://app.diagrams.net) or the VS Code "Draw.io Integration" extension, then re-export with `drawio --export --format svg --output atc_pid_architecture.svg atc_pid_architecture.drawio`.*

In higher modes (HOLD, LOITER, AUTO, etc.) an outer **heading** loop (`ATC_STR_ANG_P`) wraps the yaw-rate loop, converting heading error to a desired yaw rate. ACRO bypasses that outer loop — the pilot stick commands yaw rate directly.

---

## Implementation references

The PID-internal parameters (`_P`, `_I`, `_D`, `_FF`, `_IMAX`, `_FLT*`, `_SMAX`, `_PDMX`, `_D_FF`, `_NTF`, `_NEF`) are not implemented in `AR_AttitudeControl.cpp` directly. That file holds two `AC_PID` instances — one for the [steering-rate loop (line 116)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L116) and one for the [speed loop (line 182)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L182) — and the `_P` / `_I` / etc. parameters are sub-group fields of those `AC_PID` instances. The actual P/I/D/FF arithmetic runs once per cycle in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105) in `AC_PID.cpp`.

Per-parameter **Source:** links below point to:
- The `AP_GROUPINFO` macro that declares the parameter (its name, range, storage)
- The call site (function or line) where the parameter's value actually changes behavior

All links are pinned to `master`. Line numbers can drift over time; if a link doesn't land where described, search the file for the parameter name.

---

## Speed Control Parameters

### `ATC_SPEED_P`
- **Description:** Converts speed error (m/s) to normalized motor output. Proportional gain.
- **Units:** (motor effort)/(m/s) — output ∈ [−1, +1]
- **Range:** 0.010 – 2.000 &nbsp; **Default:** 0.20 &nbsp; **Vehicle:** 1.0
- **Notes:** Standard $K_p$ in the speed PID. Increasing it shortens rise time but increases overshoot and noise sensitivity. Vehicle ships with $K_p=1.0$, five times the source default — likely tuned for the marine drag profile.
- **Source:** [`P` defined at AC_PID.cpp:7](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L7) → consumed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_I`
- **Description:** Integrates speed error over time to drive steady-state error to zero.
- **Units:** (motor effort)/(m/s · s)
- **Range:** 0.000 – 2.000 &nbsp; **Default:** 0.20 &nbsp; **Vehicle:** 0.2
- **Notes:** $K_i$ in the speed PID. Required when the plant has unmodeled drag or a constant disturbance (current, wind). The **I-term's contribution** to the controller output (i.e. the integrator state times $K_i$) is clamped to ±`ATC_SPEED_IMAX` — this is the classic anti-windup mechanism. It does *not* clamp the summed P+I+D output (that's `ATC_SPEED_PDMX` / `_SMAX`'s job). You can verify in the logs: `PIDA_I` is the clamped I-term output, separate from `PIDA_P`, `PIDA_D`.
- **Source:** [`I` defined at AC_PID.cpp:11](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L11) → integrator updated in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_D`
- **Description:** Acts on rate of change of speed error.
- **Units:** (motor effort)/(m/s · s)
- **Range:** 0.000 – 0.400 &nbsp; **Default:** 0.00 &nbsp; **Vehicle:** 0
- **Notes:** Rarely useful for surge speed control on a USV — speed is GPS-noisy and derivative kick is undesirable. Leave at 0 unless you have a specific reason.
- **Source:** [`D` defined at AC_PID.cpp:15](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L15) → derivative computed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).


### `ATC_SPEED_FF`
- **Description:** Feed-forward gain — output proportional to the **setpoint** (not the error).
- **Units:** (motor effort)/(m/s)
- **Range:** 0.000 – 0.500 &nbsp; **Default:** 0.0 &nbsp; **Vehicle:** 0
- **Notes:** Enables predictive control: if you know empirically that 50 % throttle produces 2 m/s steady speed, an FF of 0.25 gives the right baseline output before the PID does any work. Lets you reduce $K_p$ and $K_i$ while keeping fast tracking. Conceptually equivalent to inverting the steady-state plant gain.  % CLAUDE: Explain how the this relates to the CRUISE_THROTTLE and CRUISE_SPEED parameters used in the "Cruise Throttle and Cruise Speed (Throttle Baseline)" section of this document: https://ardupilot.org/rover/docs/rover-tuning-throttle-and-speed.html
- **Source:** [`FF` defined at AC_PID.cpp:19](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L19) → applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105). Direct read in [`AR_AttitudeControl::get_throttle_out_speed()` at line 321](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L321).

### `ATC_SPEED_IMAX`
- **Description:** Anti-windup clamp on the integral term's output contribution.
- **Range:** 0.000 – 1.000 &nbsp; **Default:** 1.00 &nbsp; **Vehicle:** 1.0
- **Notes:** Prevents integral windup during saturation (e.g. low battery, prop fouled). Matches the normalized motor output range, so the default lets the I term fully command the motor on its own.  % CLAUDE: Can you explain the units of this?
- **Source:** [`IMAX` defined at AC_PID.cpp:23](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L23) → integrator clamping in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_FLTT` &nbsp;/&nbsp; `ATC_SPEED_FLTE` &nbsp;/&nbsp; `ATC_SPEED_FLTD`
- **Description:** Cutoff frequencies (Hz) for the low pass filters on the **target**, **error**, and **derivative** signals respectively.
- **Range:** 0.000 – 100.000 Hz &nbsp; **Default (FLTE):** 10 Hz &nbsp; **Default (FLTT, FLTD):** 0 (off)
- **Vehicle:** FLTT=0, FLTE=10, FLTD=0
- **Notes:** Three filter taps % CLAUDE: Audience won't understand fitler taps.
 that decouple noise, target step shape, and derivative noise % CLAUDE: This is also confusing.
  Lab default of FLTE=10 Hz is well above the surge dynamics (~0.5–2 Hz bandwidth) so it does not affect step-response analysis. Set FLTT > 0 to soften an aggressive setpoint command; leave FLTD at 0 unless using ATC_SPEED_D. % CLAUDE: Why?
  % CLAUDE: How are these implemented?  Are the first order linear filters?  Why are rate limiters uses for inputs and outputs and a "filter" used for these?
- **Source:** [`FLTT` at AC_PID.cpp:31](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L31), [`FLTE` at AC_PID.cpp:35](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L35), [`FLTD` at AC_PID.cpp:39](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L39) → filters applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).


### `ATC_SPEED_FILT` *(legacy)*
- **Description:** Pre-FLTT/FLTE/FLTD filter parameter — superseded by the three split filters above.
- **Default:** 10 Hz
- **Notes:** Kept for backward compatibility. Modern firmware uses FLTT/FLTE/FLTD. If both are set, the split parameters take precedence. % CLAUDE: What does "split parameter" mean?  Why the change, just to the name?   what does "set" mean in this context - if there is a default this would suggest that it is "set" by default which contridicts the instructions?
- **Source:** Legacy parameter — typically aliased to FLTE. Search [`AC_PID.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp) for `FILT` to see the alias / migration logic.

### `ATC_SPEED_SMAX`
- **Description:** Slew rate limit on the PID output to prevent oscillation when control authority is exceeded.
- **Range:** 0 – 200 &nbsp; **Default:** 0 (disabled) &nbsp; **Vehicle:** 0
- **Notes:** Advanced anti-oscillation safety net. Leave disabled for tuning experiments — it can mask the controller's actual closed-loop behavior.
- **Source:** [`SMAX` defined at AC_PID.cpp:43](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L43) → slew limiter applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_PDMX`
- **Description:** Maximum combined P+D output magnitude.
- **Default:** 0 (disabled) &nbsp; **Vehicle:** 0
- **Notes:** Saturates the proportional + derivative path before the I term is added, so the integrator can still trim small offsets even when P is railed. Not relevant for our experiments.
- **Source:** [`PDMX` defined at AC_PID.cpp:49](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L49) → P+D clamping in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_D_FF`
- **Description:** Feed-forward gain on the derivative of the setpoint.
- **Default:** 0 &nbsp; **Vehicle:** 0
- **Notes:** Predicts the motor effort needed to follow a changing setpoint (acceleration). Useful only with smooth setpoint trajectories.
- **Source:** [`D_FF` defined at AC_PID.cpp:54](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L54) → applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_SPEED_NTF` &nbsp;/&nbsp; `ATC_SPEED_NEF`
- **Description:** Indices into the vehicle's notch filter bank for the target and error signals.
- **Default:** 0 (no notch)
- **Notes:** Used to suppress narrow-band resonances (motor cogging, structural modes). Not needed for boats.
- **Source:** [`NTF` at AC_PID.cpp:60](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L60), [`NEF` at AC_PID.cpp:65](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L65) → consumed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_ACCEL_MAX`
- **Description:** Maximum commanded acceleration applied to the speed setpoint via a rate limiter.
- **Units:** m/s² &nbsp; **Range:** 0 – 10 &nbsp; **Default:** 1.0 &nbsp; **Vehicle:** 1.0
- **Notes:** **Critical for the lab.** A nonzero value means the PID never sees a true step input — the setpoint ramps at this rate. To capture the closed-loop step response, set this to **0** (disables the limiter; setpoint follows the stick instantly). See Section *Filtering and Rate-Limiting* in the lab chapter.
- **Source:** [Defined at AR_AttitudeControl.cpp:189](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L189) → consumed in [`AR_AttitudeControl::get_desired_speed_accel_limited()` (lines 330, 347)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L330).

### `ATC_DECEL_MAX`
- **Description:** Maximum deceleration; if 0, falls back to `ATC_ACCEL_MAX`.
- **Units:** m/s² &nbsp; **Range:** 0 – 10 &nbsp; **Default:** 0 &nbsp; **Vehicle:** 0
- **Notes:** Allows asymmetric ramping (slower stop than start). Default 0 means symmetric.
- **Source:** [Defined at AR_AttitudeControl.cpp:205](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L205) → consumed in [`AR_AttitudeControl::get_desired_speed_accel_limited()` (lines 348, 357)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L348).

### `ATC_BRAKE`
- **Description:** When enabled, the controller can command **negative** motor output to actively decelerate.
- **Range:** 0 / 1 &nbsp; **Default:** 1 &nbsp; **Vehicle:** 1
- **Notes:** Required for boats with reversible ESCs. Without it, deceleration relies entirely on hydrodynamic drag.
- **Source:** [Defined at AR_AttitudeControl.cpp:198](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L198) → consumed in [`AR_AttitudeControl::get_throttle_out_speed()` (line 326)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L326).

### `ATC_STOP_SPEED`
- **Description:** Below this speed, motor output is forced to zero.
- **Units:** m/s &nbsp; **Range:** 0.0 – 0.5 &nbsp; **Default:** 0.1 &nbsp; **Vehicle:** 0.1
- **Notes:** Prevents motor jitter / arming-detect issues at near-zero speeds. Active only in modes that rely on the controller deciding when "stopped" (HOLD, AUTO).
- **Source:** [Defined at AR_AttitudeControl.cpp:211](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L211) → consumed in [`AR_AttitudeControl::get_throttle_out_stop()` (line 340)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L340).

---

## Steering / Yaw-Rate Control Parameters

### `ATC_STR_RAT_P`
- **Description:** Converts yaw-rate error (rad/s) to normalized rudder/skid-steer output.
- **Range:** 0.000 – 2.000 &nbsp; **Default:** 0.20 &nbsp; **Vehicle:** 0.2
- **Notes:** $K_p$ for the yaw-rate loop. Same role as `ATC_SPEED_P` but in the steering channel.
- **Source:** [`P` defined at AC_PID.cpp:7](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L7) → consumed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_RAT_I`
- **Description:** Integral gain for yaw-rate error.
- **Range:** 0.000 – 2.000 &nbsp; **Default:** 0.20 &nbsp; **Vehicle:** 0.2
- **Notes:** Eliminates steady-state yaw-rate error from rudder asymmetry, current, or unbalanced thrust. Anti-wound to ±`ATC_STR_RAT_IMAX`.
- **Source:** [`I` defined at AC_PID.cpp:11](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L11) → integrator updated in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_RAT_D`
- **Description:** Derivative gain on yaw-rate error.
- **Range:** 0.000 – 0.400 &nbsp; **Default:** 0.00 &nbsp; **Vehicle:** 0
- **Notes:** Sometimes useful to damp ringing on aggressive turns, but yaw-rate is already a derivative (of heading) so adding D acts on $\ddot\psi$ — very noisy. Use sparingly.
- **Source:** [`D` defined at AC_PID.cpp:15](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L15) → derivative computed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_RAT_FF`
- **Description:** Feed-forward gain — rudder output proportional to the desired yaw rate.
- **Range:** 0.000 – 3.000 &nbsp; **Default:** 0.20 &nbsp; **Vehicle:** 2.0
- **Notes:** Major contribution to control authority on USVs. The vehicle ships with FF=2.0 (10× source default), reflecting that for a single-rudder boat, the steady rudder needed to hold a given yaw rate is approximately linear in the desired rate. **For the lab step-response experiment, set FF=0** so the response reflects the PID gains alone (per the lab chapter procedure table).
- **Source:** [`FF` defined at AC_PID.cpp:19](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L19) → applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105). Direct read in [`AR_AttitudeControl::get_steering_out_rate()` at line 283](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L283).

### `ATC_STR_RAT_IMAX`
- **Description:** Anti-windup clamp for the I term.
- **Range:** 0.000 – 1.000 &nbsp; **Default:** 1.00 &nbsp; **Vehicle:** 1.0
- **Source:** [`IMAX` defined at AC_PID.cpp:23](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L23) → integrator clamping in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_RAT_FLTT` &nbsp;/&nbsp; `ATC_STR_RAT_FLTE` &nbsp;/&nbsp; `ATC_STR_RAT_FLTD`
- **Description:** LPF cutoffs for target, error, and derivative paths.
- **Range:** 0–100 Hz &nbsp; **Default (FLTE):** 10 Hz &nbsp; **Vehicle:** FLTT=0, FLTE=10, FLTD=0
- **Notes:** IMU yaw rate is much faster than GPS speed, so these filters matter more here than on the speed channel. Default FLTE=10 Hz attenuates IMU sensor noise without affecting yaw-rate dynamics (~1–5 Hz typical bandwidth).
- **Source:** [`FLTT` at AC_PID.cpp:31](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L31), [`FLTE` at AC_PID.cpp:35](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L35), [`FLTD` at AC_PID.cpp:39](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L39) → applied in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_RAT_FILT` *(legacy)*
- **Description:** Pre-split filter parameter, superseded.
- **Default:** 10 Hz
- **Source:** Legacy parameter — see [`AC_PID.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp) and search for `FILT` to see the alias / migration logic.

### `ATC_STR_RAT_SMAX` &nbsp;/&nbsp; `ATC_STR_RAT_PDMX` &nbsp;/&nbsp; `ATC_STR_RAT_D_FF` &nbsp;/&nbsp; `ATC_STR_RAT_NTF` &nbsp;/&nbsp; `ATC_STR_RAT_NEF`
Same role as the equivalent `ATC_SPEED_*` parameters above. All default to 0 (disabled) on the vehicle.
- **Source:** All defined in [`AC_PID.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp) — [`SMAX:43`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L43), [`PDMX:49`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L49), [`D_FF:54`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L54), [`NTF:60`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L60), [`NEF:65`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L65) → consumed in [`AC_PID::update_all()`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp#L105).

### `ATC_STR_ANG_P`
- **Description:** Outer-loop heading-hold P gain. Converts heading error (rad) to desired yaw rate (rad/s).
- **Range:** 1.000 – 10.000 &nbsp; **Default:** 2.0 &nbsp; **Vehicle:** 2.0
- **Notes:** **Not active in ACRO mode.** Used by HOLD, LOITER, AUTO, etc. where the autopilot is responsible for heading. Together with the yaw-rate PID it forms the cascaded heading controller. In our class the yaw-rate loop is the inner loop; this parameter wraps it for higher modes.
- **Source:** [Defined at AR_AttitudeControl.cpp:158](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L158) → consumed in [`AR_AttitudeControl::get_turn_rate_from_heading()` at line 241](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L241).

### `ATC_STR_ACC_MAX`
- **Description:** Maximum commanded yaw acceleration applied as a rate limiter on the yaw-rate setpoint.
- **Units:** deg/s² &nbsp; **Range:** 0 – 1000 &nbsp; **Default:** 120 &nbsp; **Vehicle:** 120
- **Notes:** Yaw analogue of `ATC_ACCEL_MAX`. **Set to 0 for the lab step-response experiment** so the PID sees a true step from the steering stick.
- **Source:** [Defined at AR_AttitudeControl.cpp:167](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L167) → consumed in [`AR_AttitudeControl::get_steering_out_rate()` (lines 261, 268)](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L261).

### `ATC_STR_DEC_MAX`
- **Description:** Yaw deceleration limit; if 0 falls back to `ATC_STR_ACC_MAX`.
- **Units:** deg/s² &nbsp; **Range:** 0 – 1000 &nbsp; **Default:** 0 &nbsp; **Vehicle:** 0
- **Source:** [Defined at AR_AttitudeControl.cpp:398](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L398) → consumed in [`AR_AttitudeControl::get_turn_rate_from_heading()` at line 254](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L254).

### `ATC_STR_RAT_MAX`
- **Description:** Hard cap on the commanded yaw rate.
- **Units:** deg/s &nbsp; **Range:** 0 – 1000 &nbsp; **Default:** 120 &nbsp; **Vehicle:** 36
- **Notes:** The vehicle's 36 deg/s cap matches the `ACRO_TURN_RATE` parameter — both default to the value advertised on the RC stick at full deflection. Reduces sensitivity of the steering stick. Increase if you want a more responsive boat (and better step amplitude in your data).  % CLAUDE: Say more about how this is implemented.
- **Source:** [Defined at AR_AttitudeControl.cpp:176](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L176) → consumed in [`AR_AttitudeControl::get_steering_out_rate()` at line 272](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L272).

### `ATC_TURN_MAX_G`
- **Description:** Maximum turning acceleration (lateral g) used to prevent rolling/slipping.
- **Units:** g &nbsp; **Range:** 0.1 – 10 &nbsp; **Default:** 0.6 &nbsp; **Vehicle:** 0.6
- **Notes:** Coordinated-turn safety: at high speeds, the autopilot reduces achievable yaw rate to keep lateral acceleration ≤ this value. Relevant in higher modes (AUTO) where the autopilot plans turns; in ACRO the pilot is in charge so this rarely engages.  % CLAUDE: I'm confused, wouldn't this be a rate limiter similer to the max accel value for speed?
- **Source:** [Defined at AR_AttitudeControl.cpp:381](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L381) → consumed in [`AR_AttitudeControl::get_steering_out_rate()` at line 289](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp#L289).

---

## Quick reference — recommended values for our lab

| Parameter | Default value | Lab step-response setting | Notes |
|-----------|--------------:|--------------------------:|-------|
| `ATC_ACCEL_MAX` | 1.0 m/s² | **0** | Disable speed cmd rate limiter |
| `ATC_STR_ACC_MAX` | 120 deg/s² | **0** | Disable yaw-rate cmd rate limiter |
| `ATC_STR_RAT_FF` | 2.0 | **0** | Isolate PID response from FF |
| `ATC_SPEED_P` | 1.0 | tune | Start point for surge tuning |
| `ATC_SPEED_I` | 0.2 | tune | Increase if steady-state offset |
| `ATC_STR_RAT_P` | 0.2 | tune | Start point for yaw tuning |
| `ATC_STR_RAT_I` | 0.2 | tune | Increase if steady-state offset |

**Restore the rate limiters and FF after the lab** — they are useful in normal operation; we disable them only to expose the underlying PID dynamics.

---

## Useful source/code references

- [`AR_AttitudeControl.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.cpp) — parameter definitions, default values, and PID call sites
- [`AR_AttitudeControl.h`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/APM_Control/AR_AttitudeControl.h) — class interface
- [`AC_PID.cpp`](https://github.com/ArduPilot/ardupilot/blob/master/libraries/AC_PID/AC_PID.cpp) — the underlying PID implementation that all `_P`, `_I`, `_D`, `_FF`, `_FLT*`, `_IMAX`, `_SMAX`, `_PDMX` parameters configure
- [Rover ACRO mode docs](https://ardupilot.org/rover/docs/rover-acro-mode.html) — official explanation of the stick-to-rate mapping
- [Rover speed and steering tuning guide](https://ardupilot.org/rover/docs/rover-tuning-throttle-and-steering-rate.html) — official tuning recipe (different in tone from a controls-class treatment but useful for cross-reference)
