function print_pid_params(d)
% PRINT_PID_PARAMS  Print ArduPilot ATC_SPEED_* and ATC_STR_RAT_* PID gains.
%   print_pid_params(d)
%
%   d is the struct returned by load() on the .mat log.  If d does not
%   contain a `params` field (older bin2mat.py output), prints a warning.

if isfield(d, "params")
    p = d.params;
    fprintf("\n--- Surge speed PID (ATC_SPEED_*) ---\n");
    fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
        p.ATC_SPEED_P, p.ATC_SPEED_I, p.ATC_SPEED_D, p.ATC_SPEED_FF);
    fprintf("\n--- Yaw-rate PID (ATC_STR_RAT_*) ---\n");
    fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
        p.ATC_STR_RAT_P, p.ATC_STR_RAT_I, p.ATC_STR_RAT_D, p.ATC_STR_RAT_FF);
else
    fprintf("No params struct - reprocess .BIN with updated bin2mat.py\n");
end
end
