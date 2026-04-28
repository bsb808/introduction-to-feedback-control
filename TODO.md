# ME 2801 TODO

## Week 2: Modeling and Transfer Functions

- [ ] Review first draft of chapter and assignment.
- [ ] Add USV-specific examples and/or assignment exercises: surge dynamics (throttle → speed) and yaw dynamics (rudder → yaw rate) as physical motivation for first- and second-order transfer functions.

## Week 5: Block Diagrams and PID Feedback

- [ ] Refactor `pid_article` (now at `week05_blockdiagrams_pid/chapter/`) so that the portions covering basic block diagrams and proportional control stay in week 5, and the portions covering integral action, derivative action, and PID tuning move into the appropriate later weeks. The article currently spans topics that span multiple weeks.

## Week 8: Frequency Response Part 1

- [ ] Review first draft of chapter (`week08_freq_response_part1/chapter/freq_response.tex`) and companion script (`freq_response_companion.m`).

## Week 9: Frequency Response Part 2

- [ ] Review first draft of chapter (`week09_freq_response_part2/chapter/freq_response_p2.tex`) and companion script (`freq_response_p2_companion.m`).

## Terminology: ArduPilot / ArduRover / autopilot

- [ ] Audit all lab documents for consistent use of ArduPilot vocabulary.  Verify the community standard (ArduPilot = the project; ArduRover = the rover/boat firmware; autopilot = the hardware board) and apply uniformly across Lab 1 (`lab_usv_sysid.tex`), Lab 2 (`lab_usv_pid.tex`), and any future lab documents.

## Rebase

I want to do a full rebase of this project to scrub the git history and as a clean break as the project has taken a new turn.  

I want to do this in a feature branch of the repository. to manage paralel modifications.  Create this new feature branch and then put a copy of the feature branch in ~/WorkingCopies/me2801_rebase.

I'll reorganize the files and delete straggling misc files.

Then we will push the modifications and manage as a PR.

After we merge the feature branch we will Create a new github repo for this new project with a more general name.   Maybe just the name of the course - introduction to feedback control.  I need to clean up, but then copy a snapshot of the current working state over to the new github repo so that it removes all the git history.  Also copy the necessary claude content to continue sessions there.

** This is a work in progress in WorkingCopies/rebase.  Still need to finish the first draft of freq resp part 2 before we can make it all consistent.


