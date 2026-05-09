function step_response_metrics(fname, experiment, t_step_start, t_step_end, yss, X)
% STEP_RESPONSE_METRICS  Compute step metrics and plot the isolated step.
%   step_response_metrics(fname, experiment, t_step_start, t_step_end, yss)
%   step_response_metrics(..., X)
%
%   Inputs:
%       fname         path to ArduPilot .mat log produced by bin2mat.py
%       experiment    "speed" (surge, m/s) or "yaw" (yaw rate, rad/s)
%       t_step_start  elapsed seconds at step onset
%       t_step_end    elapsed seconds when response has settled
%       yss           observed steady-state value of the measurement
%       X             plot lead-in: figure starts X seconds before
%                     t_step_start (default 2.0 s)
%
%   stepinfo is computed over [t_step_start, t_step_end].
%   Plots:
%       Figure: setpoint, measured, target, and steady-state lines.
%       Figure: PID internals over the same window (if logs present).
arguments
    fname        (1,1) string
    experiment   (1,1) string
    t_step_start (1,1) double
    t_step_end   (1,1) double
    yss          (1,1) double
    X            (1,1) double = 2.0
end

log = load_and_prep(fname);
t_plot_start = t_step_start - X;

if experiment == "speed"
    % Metric window (stepinfo): [t_step_start, t_step_end]
    mask_y   = log.t_gps >= t_step_start & log.t_gps <= t_step_end;
    % Plot window: [t_plot_start, t_step_end]
    mask_yp  = log.t_gps >= t_plot_start & log.t_gps <= t_step_end;
    mask_spp = log.t_thr >= t_plot_start & log.t_thr <= t_step_end;
    t_y      = log.t_gps(mask_y)   - t_step_start;
    t_yp     = log.t_gps(mask_yp)  - t_step_start;
    t_spp    = log.t_thr(mask_spp) - t_step_start;
    y        = log.d.GPS_Spd(mask_y);
    y_plot   = log.d.GPS_Spd(mask_yp);
    sp_plot  = log.d.THR_DesSpeed(mask_spp);
    unitStr  = "m/s";
    chanStr  = "Speed";
else
    mask_y   = log.t_ster >= t_step_start & log.t_ster <= t_step_end;
    mask_yp  = log.t_ster >= t_plot_start & log.t_ster <= t_step_end;
    t_y      = log.t_ster(mask_y)  - t_step_start;
    t_yp     = log.t_ster(mask_yp) - t_step_start;
    t_spp    = t_yp;
    y        = log.d.STER_TurnRate(mask_y);
    y_plot   = log.d.STER_TurnRate(mask_yp);
    sp_plot  = log.d.STER_DesTurnRate(mask_yp);
    unitStr  = "rad/s";
    chanStr  = "Yaw rate";
end

y_final = yss;
y_init  = y(1);
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

figure(); clf();
hold on;
plot(t_spp, sp_plot, "b--", "DisplayName", "Setpoint");
plot(t_yp,  y_plot,  "r-",  "DisplayName", "Measured");
yline(y_final, "k--", "Target",       "LabelHorizontalAlignment", "left");
yline(y_ss,    "g:",  "Steady state", "LabelHorizontalAlignment", "left");
xline(0,       "k:",  "Step onset",   "LabelVerticalAlignment", "bottom");
hold off;
ylabel(sprintf("%s (%s)", chanStr, unitStr));
xlabel("Time from step onset (s)");
title(sprintf("%s Step - %s", chanStr, log.fileLabel), "Interpreter", "none");
legend("Location", "best");
grid on;

% PID internals over the plot window
%   PIDS_* = speed PID, PIDA_* = attitude (yaw-rate) PID
pid_tar = [];
if experiment == "speed" && log.has_pids
    mask_pid = log.t_pids >= t_plot_start & log.t_pids <= t_step_end;
    t_pid    = log.t_pids(mask_pid) - t_step_start;
    pid_tar  = log.d.PIDS_Tar(mask_pid);
    pid_act  = log.d.PIDS_Act(mask_pid);
    pid_P    = log.d.PIDS_P(mask_pid);
    pid_I    = log.d.PIDS_I(mask_pid);
    pid_D    = log.d.PIDS_D(mask_pid);
    pid_FF   = log.d.PIDS_FF(mask_pid);
    pid_out  = pid_P + pid_I + pid_D + pid_FF;
elseif experiment == "yaw" && log.has_pida
    mask_pid = log.t_pida >= t_plot_start & log.t_pida <= t_step_end;
    t_pid    = log.t_pida(mask_pid) - t_step_start;
    pid_tar  = log.d.PIDA_Tar(mask_pid);
    pid_act  = log.d.PIDA_Act(mask_pid);
    pid_P    = log.d.PIDA_P(mask_pid);
    pid_I    = log.d.PIDA_I(mask_pid);
    pid_D    = log.d.PIDA_D(mask_pid);
    pid_FF   = log.d.PIDA_FF(mask_pid);
    pid_out  = pid_P + pid_I + pid_D + pid_FF;
end

if ~isempty(pid_tar)
    figure(); clf();
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
end
