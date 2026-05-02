# Lab 2 Procedure Sketch

Outline of testing procedure.  This is not a step-by-step guide but and outline of some recommendations to for the lab's objective.

## Pre-Lab Prep

## Testing Process

We want to do a comparison of a few different low-level feedback designs.  The objective is to compare all the aspects of "performance" of the feedback control design to be able to understand the tradeoffs in archecture and gain tuning.

Roles: 
* Planner: Works with Mission Planner software to provide feedback on state (ARM status, Mode status) and display time response information to assist tuning.
* Scripe: Records notes to assist in post-processing logs
* Pilot: Provides input to the feedback control loop via the R/C transmitter.

For each scenario under test, you will want to record the following notes:
* Time of the note (We believe the logs are in UTC, but need to verify)
* Description - what happened next that can help untagle the log files being recorded.

For each scenario:
* Start the scenario by 
    * Scribe starts a note with the current time.
    * Planner saves the current parameter file on the computer.  Ideally the put the timestamp in the filename.
    * Pilot ARMs the autopilot (starts new log file on autopilot)
    * Plot activates ACRO mode for autopilot (engages PID feedback for speed and yaw-rate)
    * Planner confirms that MP shows in ACRO mode
* Pilot executes approximate step inputs to capture the following:
    * At least two step response trials of closed loop (ACRO mode) speed response to input of roughly 50% throttle.
    * At least two step response trials of the yaw-rate control at roughly 50% throttle and 50% rudder.  Each rudder test should include both left and right turns.
* The autopilot parameters are saved in the log file and ARMing the autopilot closes the current file and starts a new one.   For a clean run, avoid changing parameters while ARM'd - this makes it difficult to verify what parameters were active when the data was collected.
* Make sure the system is in ACRO mode before running step response.  It is easy to miss this.
* During the tuning process, you will rely mainly on the real-time graphs in MP.  You don't necessarily need to log all of those trials as you quickly iterate amoung values.
* This data collection and processing can be tricky, but diligent note taking is a big help.  You will end up with 10's of log files and stored parameter files on different computers and two timezones (local and UTC).
* It will likely take two attempts to get "clean" measures of the step response in the different conditions.  We'll plan at least two days of testing with time in between for processing.



## Notes for next time

