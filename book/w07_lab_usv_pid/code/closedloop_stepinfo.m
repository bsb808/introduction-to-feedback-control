% Closed-Loop Step Response Analysis
%
% Loads an ArduPilot .mat log, plots the setpoint, measured response, control
% effort, and PID controller internals for a speed or yaw-rate step
% experiment, then applies stepinfo to quantify rise time, settling time,
% overshoot, and steady-state error.
%
% Calls (all in this directory):
%   plot_speed_response(fname)   or   plot_yaw_response(fname)
%   step_response_metrics(fname, experiment, t_step_start, t_step_end, yss[, X])

%% 1 - User Input
clear;
close("all");
set(0, 'DefaultFigureWindowStyle', 'normal')

fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";

% Available logs:
%   A - FF only
%     Speed: 00000011.BIN_20260506_223549.mat
%     Yaw:   00000013.BIN_20260506_223627.mat
%   B - FF and PID
%     Speed: 00000015.BIN_20260506_223900.mat
%     Yaw:   00000017.BIN_20260506_223937.mat
fname      = fullfile(fdir, "00000015.BIN_20260506_223900.mat");
experiment = "speed";   % "speed"  ->  surge (m/s)  |  "yaw"  ->  yaw rate (rad/s)

%% 2 - Plot Full Response and Print PID Parameters
if experiment == "speed"
    plot_speed_response(fname);
else
    plot_yaw_response(fname);
end

%% 3 - Step Isolation
% From the figures above, read off the step boundaries (in elapsed seconds)
% and the observed steady-state value of the measurement.
t_step_start = 3.2;     % elapsed seconds at step onset
t_step_end   = 13.84;   % elapsed seconds when response has settled
yss          = 2.0;     % observed steady-state value

%% 4 - Step Metrics and Isolated Plot
% By default the plot window starts X = 2.0 s before t_step_start. Override
% with a sixth argument, e.g.:
%   step_response_metrics(fname, experiment, t_step_start, t_step_end, yss, 1.0);
step_response_metrics(fname, experiment, t_step_start, t_step_end, yss);
