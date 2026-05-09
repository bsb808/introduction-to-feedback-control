function print_pid_params(fname)
% PRINT_PID_PARAMS  Print ArduPilot ATC_SPEED_* and ATC_STR_RAT_* PID gains.
%   print_pid_params(fname)
%
%   fname is the path to a .mat log produced by bin2mat.py.  Loads the
%   file and prints the saved PID parameters.  If the file does not
%   contain a `params` field (older bin2mat.py output), prints a warning.
arguments
    fname (1,1) string
end

d = load(fname);

fprintf("\nPID parameters in %s\n", fname);

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
