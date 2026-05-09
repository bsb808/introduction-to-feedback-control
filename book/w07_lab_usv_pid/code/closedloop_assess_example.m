% Closed-Loop Step Response Analysis
%
% This example illustrates the processing of the Lab 2 log files to do the
% following:
% - Report the 
% - Plot the entire experiment so the user can identify the step
% properties.
% - Isolate the desired step response
%
% This script uses custom functions from the same directory.  See the
% individual function documentation for details. 

%% Specify the data file and the experiment type
clear;
close("all");
set(0, 'DefaultFigureWindowStyle', 'normal')
fdir = "./";
fname      = fullfile(fdir, "closedloop_assess_example.mat");
experiment = "speed";   % "speed" or "yaw"

%% Load log data as a structure and save filename for later
d = load(fname);
[dirpath, name, ext] = fileparts(fname);
[~, lastDir] = fileparts(dirpath);
flabel = fullfile(lastDir, sprintf("%s.%s", name, ext));


%% Print the pertinent controller parameters
p = d.params;
fprintf("\n--- Surge speed PID (ATC_SPEED_*) ---\n");
fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
    p.ATC_SPEED_P, p.ATC_SPEED_I, p.ATC_SPEED_D, p.ATC_SPEED_FF);
fprintf("\n--- Yaw-rate PID (ATC_STR_RAT_*) ---\n");
fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
    p.ATC_STR_RAT_P, p.ATC_STR_RAT_I, p.ATC_STR_RAT_D, p.ATC_STR_RAT_FF);


%% Plot the full response for both controllers.
t0 = min([d.PIDA_timestamp(1), d.PIDS_timestamp(1)]);

% Speed = PIDA
figure(1);
clf();
ax1 = subplot(211);
plot(d.PIDA_timestamp-t0, d.PIDA_Tar, "b--", "DisplayName", "PIDA\_Tar (setpoint/cmd)");
hold on;
plot(d.PIDA_timestamp-t0, d.PIDA_Act, "r-",  "DisplayName", "PIDA\_Act (actual)");
hold off;
ylabel("Speed (m/s)");
legend("Location", "best");
title(sprintf("Speed Loop (PIDA) <%s>", flabel), "Interpreter", "none");
grid on;

% Steering = PIDS
ax2 = subplot(212);
plot(d.PIDS_timestamp-t0, d.PIDS_Tar, "b--", "DisplayName", "PIDS\_Tar (setpoint/cmd)");
hold on;
plot(d.PIDS_timestamp-t0, d.PIDS_Act, "r-",  "DisplayName", "PIDS\_Act (actual)");
hold off;
ylabel("Speed (m/s)");
legend("Location", "best");
title(sprintf("Steering Loop (PIDS) <%s>", flabel), "Interpreter", "none");
grid on;
linkaxes([ax1, ax2], "x");

%% Isolate the step response
% From the generated figures above, find the step boundaries (in elapsed seconds)
% and the observed steady-state value of the measurement.
t_step_start = 3.28;     % elapsed seconds at step onset
t_step_end   = 14.0;   % elapsed seconds when response has settled
tar_amplitude = 2.15;   % Observed amplitude of the target (setpoint/cmd) input
act_steady_state = 1.99;     % observed steady-state value of the actual output

%% Step Metrics and Isolated Plot
% By default the plot window starts X = 2.0 s before t_step_start.
% Override with a seventh argument, e.g.:
%   step_response_metrics(d, experiment, t_step_start, t_step_end, ...
%                         tar_amplitude, act_steady_state, 1.0);
figure(2);
step_response_metrics(d, experiment, t0, t_step_start, t_step_end, ...
                      tar_amplitude, act_steady_state);
