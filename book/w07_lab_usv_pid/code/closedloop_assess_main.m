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
fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
fname      = fullfile(fdir, "00000015.BIN_20260506_223900.mat");
experiment = "speed";   % "speed"  ->  surge (m/s)  |  "yaw"  ->  yaw rate (rad/s)

% Available logs:
%   A - FF only
%     Speed: 00000011.BIN_20260506_223549.mat
%     Yaw:   00000013.BIN_20260506_223627.mat
%   B - FF and PID
%     Speed: 00000015.BIN_20260506_223900.mat
%     Yaw:   00000017.BIN_20260506_223937.mat

% Plot Full Response and Print PID Parameters
plot_full_response(fname, experiment);

% From the generated figures above, find the step boundaries (in elapsed seconds)
% and the observed steady-state value of the measurement.
t_step_start = 3.2;     % elapsed seconds at step onset
t_step_end   = 13.84;   % elapsed seconds when response has settled
yss          = 2.0;     % observed steady-state value

%% 4 - Step Metrics and Isolated Plot
% By default the plot window starts X = 2.0 s before t_step_start. Override
% with a sixth argument, e.g.:
%   step_response_metrics(fname, experiment, t_step_start, t_step_end, yss, 1.0);
step_response_metrics(fname, experiment, t_step_start, t_step_end, yss);
