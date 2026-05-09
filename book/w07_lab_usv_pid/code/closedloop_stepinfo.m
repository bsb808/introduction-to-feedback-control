% Closed-Loop Step Response Analysis
%
% Loads an ArduPilot .mat log, plots the setpoint, measured response, control
% effort, and PID controller internals for a speed or yaw-rate step
% experiment, then applies stepinfo to quantify rise time, settling time,
% overshoot, and steady-state error.

%% 1 - User Input
% Set the log file path and which controller to analyze, then run all
% sections top to bottom.
clear;
close("all");
set(0,'DefaultFigureWindowStyle','normal')

fname      = "your_log.mat";  % path to .mat file produced by bin2mat.py
experiment = "speed";         % "speed"  ->  surge (m/s)  |  "yaw"  ->  yaw rate (rad/s)

% Tuning
fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
% A - FF only
% Speed
fname = fullfile(fdir, "00000011.BIN_20260506_223549.mat");
experiment = "speed";
% Yaw-rate
fname = fullfile(fdir, "00000013.BIN_20260506_223627.mat");
experiment = "yaw";
%  B - FF and PID
% Speed
fname = fullfile(fdir, "00000015.BIN_20260506_223900.mat");
experiment = "speed";
% Yaw
% fname = fullfile(fdir, "00000017.BIN_20260506_223937.mat");
% experiment = "yaw";

% 2 - Load
fprintf("Loading %s ...\n", fname);
d = load(fname);

[dirpath, name, ext] = fileparts(fname);
[~, lastDir] = fileparts(dirpath);
fileLabel = fullfile(lastDir, sprintf("%s.%s", name, ext));

% Report PID Parameters
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

% Define Signals
% Elapsed seconds from the earliest message across all channels
t0 = min([d.THR_timestamp(1), d.GPS_timestamp(1), ...
          d.STER_timestamp(1), d.RCOU_timestamp(1)]);

t_thr  = d.THR_timestamp  - t0;
t_gps  = d.GPS_timestamp  - t0;
t_ster = d.STER_timestamp - t0;
t_rcou = d.RCOU_timestamp - t0;

% PID internal log messages (PIDS = steering/yaw-rate, PIDT = throttle/speed)
has_pids = isfield(d, "PIDS_timestamp");
has_pidt = isfield(d, "PIDT_timestamp");
if has_pids, t_pids = d.PIDS_timestamp - t0; end
if has_pidt, t_pidt = d.PIDT_timestamp - t0; end

% PWM -> normalized effort (piecewise; adjust inzero/inmax/inmin to match vehicle params)
inzero = 1500;  inmax = 1900;  inmin = 1100;
throttle_norm = normalize_pwm(d.RCOU_C3, inzero, inmax, inmin);
rudder_norm   = normalize_pwm(d.RCOU_C1, inzero, inmax, inmin);

% Plot Full Timeseries
% Figure 1: setpoint, measured response, and control effort.  Figure 2: PID
% controller internals (Tar/Act, P/I/D/FF terms, total output).  Inspect both
% to find the elapsed-second boundaries of the step; enter those values in
% Section 5.
if experiment == "speed"
    figure(1); clf();
    ax1 = subplot(211);
    hold on;
    plot(t_thr, d.THR_DesSpeed, "b--", "DisplayName", "Setpoint");
    plot(t_gps, d.GPS_Spd,      "r-",  "DisplayName", "Measured (GPS)");
    hold off;
    ylabel("Speed (m/s)");
    legend("Location", "best");
    title(sprintf("Surge Step Response - %s", fileLabel), "Interpreter", "none");
    grid on;
    ax2 = subplot(212);
    plot(t_rcou, throttle_norm, "k-", "DisplayName", "Throttle");
    ylabel("Throttle effort (norm.)");
    ylim([-1.05, 1.05]);
    xlabel("Elapsed time (s)");
    legend("Location", "best");
    grid on;
    linkaxes([ax1, ax2], "x");

    if has_pidt
        figure(2); clf();
        ax1 = subplot(311);
        hold on;
        plot(t_pidt, d.PIDT_Tar, "b--", "DisplayName", "Target");
        plot(t_pidt, d.PIDT_Act, "r-",  "DisplayName", "Actual");
        hold off;
        ylabel("Speed (m/s)");
        legend("Location", "best");
        title(sprintf("Speed PID Internals - %s", fileLabel), "Interpreter", "none");
        grid on;
        ax2 = subplot(312);
        hold on;
        plot(t_pidt, d.PIDT_P,  "b-",  "DisplayName", "P");
        plot(t_pidt, d.PIDT_I,  "g-",  "DisplayName", "I");
        plot(t_pidt, d.PIDT_D,  "r-",  "DisplayName", "D");
        plot(t_pidt, d.PIDT_FF, "m--", "DisplayName", "FF");
        hold off;
        ylabel("PID terms");
        legend("Location", "best");
        grid on;
        ax3 = subplot(313);
        plot(t_pidt, d.PIDT_Out, "k-", "DisplayName", "Output");
        ylabel("PID output");
        xlabel("Elapsed time (s)");
        legend("Location", "best");
        grid on;
        linkaxes([ax1, ax2, ax3], "x");
    else
        fprintf("PIDT messages not found in log - no speed PID internals plot.\n");
    end
else
    figure(1); clf();
    ax1 = subplot(211);
    hold on;
    plot(t_ster, d.STER_DesTurnRate, "b--", "DisplayName", "Setpoint");
    plot(t_ster, d.STER_TurnRate,    "r-",  "DisplayName", "Measured");
    hold off;
    ylabel("Yaw rate (rad/s)");
    legend("Location", "best");
    title(sprintf("Yaw-Rate Step Response - %s", fileLabel), "Interpreter", "none");
    grid on;
    ax2 = subplot(212);
    plot(t_rcou, rudder_norm, "k-", "DisplayName", "Rudder");
    ylabel("Rudder effort (norm.)");
    ylim([-1.05, 1.05]);
    xlabel("Elapsed time (s)");
    legend("Location", "best");
    grid on;
    linkaxes([ax1, ax2], "x");

    if has_pids
        figure(2); clf();
        ax1 = subplot(311);
        hold on;
        plot(t_pids, d.PIDS_Tar, "b--", "DisplayName", "Target");
        plot(t_pids, d.PIDS_Act, "r-",  "DisplayName", "Actual");
        hold off;
        ylabel("Yaw rate (rad/s)");
        legend("Location", "best");
        title(sprintf("Yaw-Rate PID Internals - %s", fileLabel), "Interpreter", "none");
        grid on;
        ax2 = subplot(312);
        hold on;
        plot(t_pids, d.PIDS_P,  "b-",  "DisplayName", "P");
        plot(t_pids, d.PIDS_I,  "g-",  "DisplayName", "I");
        plot(t_pids, d.PIDS_D,  "r-",  "DisplayName", "D");
        plot(t_pids, d.PIDS_FF, "m--", "DisplayName", "FF");
        hold off;
        ylabel("PID terms");
        legend("Location", "best");
        grid on;
        ax3 = subplot(313);
        plot(t_pids, d.PIDS_P + d.PIDS_I + d.PIDS_D + d.PIDS_FF, "k-", "DisplayName", "Output");
        ylabel("PID output");
        xlabel("Elapsed time (s)");
        legend("Location", "best");
        grid on;
        linkaxes([ax1, ax2, ax3], "x");
    else
        fprintf("PIDS messages not found in log - no yaw-rate PID internals plot.\n");
    end
end

% Step Isolation
% From the figure (use zoom, data tips, etc.) report the following values
% needed to isolate and charactertize the step reponse.
% When the step command begins
t_step_start = 3.2;             % <- elapsed seconds at step onset
% When do you want ot consider the step response at steady state?
t_step_end   = 13.84;    % <- elapsed seconds when response has settled
% Specify the value of "Measured" at "steady state".   This is imperfect,
% because the data is rarely perfect.
yss = 2.0; 

%% 6 - Step Response Metrics
% stepinfo uses the 2% settling criterion.  Steady-state error is the mean
% of the last 20% of the window compared to the commanded setpoint.
if experiment == "speed"
    mask_y  = t_gps >= t_step_start & t_gps <= t_step_end;
    mask_sp = t_thr >= t_step_start & t_thr <= t_step_end;
    t_y     = t_gps(mask_y) - t_step_start;
    y       = d.GPS_Spd(mask_y);
    sp      = d.THR_DesSpeed(mask_sp);
    y_final = yss; %sp(end);
    unitStr = "m/s";
    chanStr = "Speed";
else
    mask_y  = t_ster >= t_step_start & t_ster <= t_step_end;
    t_y     = t_ster(mask_y) - t_step_start;
    y       = d.STER_TurnRate(mask_y);
    sp      = d.STER_DesTurnRate(mask_y);
    y_final = yss; %sp(end);
    unitStr = "rad/s";
    chanStr = "Yaw rate";
end

y_init = y(1);
S = stepinfo(y(:), t_y(:), y_final, y_init);

n_tail       = max(1, round(0.2 * numel(y)));
y_ss         = mean(y(end - n_tail + 1 : end));
ss_error     = y_final - y_ss;
ss_error_pct = 100 * ss_error / abs(y_final);

fprintf("\n=== %s step-response metrics ===\n", chanStr);
fprintf("  Setpoint:              %.4f %s\n", y_final, unitStr);
fprintf("  Rise time (10%%-90%%):  %.3f s\n",  S.RiseTime);
fprintf("  Settling time (2%%):    %.3f s\n",  S.SettlingTime);
fprintf("  Overshoot:             %.1f %%\n", S.Overshoot);
fprintf("  Steady-state value:    %.4f %s\n",  y_ss, unitStr);
fprintf("  Steady-state error:    %.4f %s  (%.1f %%)\n", ss_error, unitStr, ss_error_pct);

%% 7 - Step Response Plots
% Figure 3: isolated step window (setpoint, measured, steady-state mean).
% Figure 4: PID internals over the same window.
figure(3); clf();
hold on;
plot(t_y, y, "r-", "DisplayName", "Measured");
yline(y_final, "b--", "Setpoint",     "LabelHorizontalAlignment", "left");
yline(y_ss,    "g:",  "Steady state", "LabelHorizontalAlignment", "left");
hold off;
ylabel(sprintf("%s (%s)", chanStr, unitStr));
xlabel("Time from step onset (s)");
title(sprintf("%s Step - %s", chanStr, fileLabel), "Interpreter", "none");
legend("Location", "best");
grid on;

% PID internals over the step window (Figure 4)
pid_tar = [];
if experiment == "speed" && has_pidt
    mask_pid = t_pidt >= t_step_start & t_pidt <= t_step_end;
    t_pid   = t_pidt(mask_pid) - t_step_start;
    pid_tar = d.PIDT_Tar(mask_pid);
    pid_act = d.PIDT_Act(mask_pid);
    pid_P   = d.PIDT_P(mask_pid);
    pid_I   = d.PIDT_I(mask_pid);
    pid_D   = d.PIDT_D(mask_pid);
    pid_FF  = d.PIDT_FF(mask_pid);
    pid_out = d.PIDT_Out(mask_pid);
elseif experiment == "yaw" && has_pids
    mask_pid = t_pids >= t_step_start & t_pids <= t_step_end;
    t_pid   = t_pids(mask_pid) - t_step_start;
    pid_tar = d.PIDS_Tar(mask_pid);
    pid_act = d.PIDS_Act(mask_pid);
    pid_P   = d.PIDS_P(mask_pid);
    pid_I   = d.PIDS_I(mask_pid);
    pid_D   = d.PIDS_D(mask_pid);
    pid_FF  = d.PIDS_FF(mask_pid);
    pid_out = pid_P + pid_I + pid_D + pid_FF;
end

if ~isempty(pid_tar)
    figure(4); clf();
    ax1 = subplot(311);
    hold on;
    plot(t_pid, pid_tar, "b--", "DisplayName", "Target");
    plot(t_pid, pid_act, "r-",  "DisplayName", "Actual");
    hold off;
    ylabel(sprintf("%s (%s)", chanStr, unitStr));
    legend("Location", "best");
    title(sprintf("%s PID Internals - Step Window", chanStr), "Interpreter", "none");
    grid on;
    ax2 = subplot(312);
    hold on;
    plot(t_pid, pid_P,  "b-",  "DisplayName", "P");
    plot(t_pid, pid_I,  "g-",  "DisplayName", "I");
    plot(t_pid, pid_D,  "r-",  "DisplayName", "D");
    plot(t_pid, pid_FF, "m--", "DisplayName", "FF");
    hold off;
    ylabel("PID terms");
    legend("Location", "best");
    grid on;
    ax3 = subplot(313);
    plot(t_pid, pid_out, "k-", "DisplayName", "Output");
    ylabel("PID output");
    xlabel("Time from step onset (s)");
    legend("Location", "best");
    grid on;
    linkaxes([ax1, ax2, ax3], "x");
end

function out = normalize_pwm(pwm, inzero, inmax, inmin)
    out = zeros(size(pwm));
    pos = pwm >= inzero;
    out( pos) = (pwm( pos) - inzero) / (inmax - inzero);
    out(~pos) = (pwm(~pos) - inzero) / (inzero - inmin);
end
