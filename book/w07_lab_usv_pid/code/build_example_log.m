% BUILD_EXAMPLE_LOG
%
% Instructor-side utility that builds a minimal-size .mat file containing
% only the channels read by closedloop_assess_example.m (and the helper
% step_response_metrics).  The output is small enough to ship inside the
% course repo so students do not need to download a multi-megabyte
% ArduPilot log to run the example.
%
% The example workflow touches exactly these fields on the loaded struct:
%   params.ATC_SPEED_{P,I,D,FF}                 (speed PID gains)
%   params.ATC_STR_RAT_{P,I,D,FF}               (yaw-rate PID gains)
%   PIDA_{timestamp,Tar,Act,P,I,D,FF}           (throttle / speed loop)
%   PIDS_{timestamp,Tar,Act,P,I,D,FF}           (steering / yaw-rate loop)
%
% Every other field from the source log is dropped, including the unused
% members of the ArduPilot params struct.

clear;

%% Inputs
% Source: full bin2mat.py output (path is instructor-machine-specific).
src = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/00000015.BIN_20260506_223900.mat";

% Destination: alongside the example script in the public repo.
dst = fullfile(fileparts(mfilename('fullpath')), "closedloop_assess_example.mat");

%% Load source
fprintf("Loading source: %s\n", src);
src_data = load(src);

%% Build minimal output struct
out = struct();

% Subset params struct to just the gains the example prints
gain_fields = ["ATC_SPEED_P",   "ATC_SPEED_I",   "ATC_SPEED_D",   "ATC_SPEED_FF", ...
               "ATC_STR_RAT_P", "ATC_STR_RAT_I", "ATC_STR_RAT_D", "ATC_STR_RAT_FF"];
out.params = struct();
for f = gain_fields
    out.params.(f) = src_data.params.(f);
end

% Copy the PID channel arrays
pid_fields = ["timestamp", "Tar", "Act", "P", "I", "D", "FF"];
for prefix = ["PIDA", "PIDS"]
    for f = pid_fields
        name = sprintf("%s_%s", prefix, f);
        out.(name) = src_data.(name);
    end
end

%% Save (default '-v7' format is zlib-compressed; smaller than '-v6'/'-v4')
% '-struct' writes each field of `out` as a top-level variable in the .mat
% file, so the example script can `d = load(...)` and access d.PIDA_Tar etc.
save(dst, "-struct", "out");

%% Report
src_info = dir(src);
dst_info = dir(dst);
fprintf("\nSource:  %s  (%.1f kB)\n", src_info.name, src_info.bytes/1024);
fprintf("Output:  %s  (%.1f kB)\n", dst_info.name, dst_info.bytes/1024);
fprintf("Reduction: %.1fx smaller\n", src_info.bytes / dst_info.bytes);
