# Next Trial Run — Notes and Pre-Lab Checklist

## Data Logging: Increase Sample Rates

Current rates observed in logs are lower than ideal for step-response analysis:

| Message | Current | Target |
|---------|---------|--------|
| GPS     | 5 Hz    | 10 Hz (or higher — see below) |
| THR     | 10 Hz   | 25–50 Hz |
| STER    | 10 Hz   | 25–50 Hz |
| RCOU    | 10 Hz   | 25–50 Hz |

### Parameters to change before the run

**In Mission Planner → Config → Full Parameter List:**

- `LOG_RATE_HZ` — increase from 10 to **25** or **50**
  (controls THR, STER, RCOU log rate; 50 Hz is the main-loop ceiling for Rover)

- `GPS_RATE_MS` — decrease from 200 to **100** (= 10 Hz)
  (lower ms = faster polling)

Reboot the autopilot after changing parameters.

### Hero3 GPS — experiment with higher rates

The Hero3 (CubePilot HERE3) receiver may support rates above 10 Hz depending on
which u-blox chip variant is installed (M8P supports up to 10 Hz; F9P variants
can reach 20 Hz).  To test:

1. Confirm the chip variant from the HERE3 datasheet or ArduPilot `GPS` log
   message `HDop`/`NSats` fields.
2. Try `GPS_RATE_MS = 100` (10 Hz) first and verify it appears in the log.
3. If the chip supports it, try `GPS_RATE_MS = 56` (~18 Hz) or `50` (20 Hz).
4. Check the BIN log after the run — if the GPS message count per second matches
   the target rate, the hardware accepted it.  If it reverts to 5 Hz, the module
   is capping itself.

> **Note:** `GPS_RATE_MS` only controls ArduPilot's polling interval; the GPS
> module must itself be configured (or auto-configured by ArduPilot on startup)
> to output at that rate.  ArduPilot auto-configures u-blox modules via UART at
> startup, so changing `GPS_RATE_MS` alone is usually sufficient.

## Watch for SD Card Overruns

Higher log rates increase SD write load.  After the run, check for `EV` log
messages with value **10** (log buffer full / data dropped).  If present, drop
`LOG_RATE_HZ` back to 25 Hz.

## Pre-Trial Checklist

- [ ] Parameter file saved with timestamp before arming (Planner role)
- [ ] `LOG_RATE_HZ` confirmed at new value via Mission Planner
- [ ] `GPS_RATE_MS` confirmed at new value via Mission Planner
- [ ] GPS lock acquired (green LED on HERE3), NSats ≥ 8
- [ ] Autopilot rebooted after any parameter changes
- [ ] Scribe has UTC time reference ready (phone NTP or Mission Planner HUD clock)
- [ ] Confirm ACRO mode engages correctly before moving to open water
