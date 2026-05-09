function S = step_response_metrics(d, experiment, t0, t_step_start, t_step_end, tar_amplitude, act_steady_state, options)
% STEP_RESPONSE_METRICS  Plot PID internals and report step-response metrics.
% S = step_response_metrics(d, experiment, t0, t_step_start, t_step_end, ...
%                         tar_amplitude, act_steady_state)
% S = step_response_metrics(..., Name=Value)
%
%   Returns a struct S with fields:
%       RiseTime          (s)         from stepinfo (10%-90%)
%       SettlingTime      (s)         from stepinfo (2% criterion)
%       Overshoot         (%)         from stepinfo
%       Peak              (units)     from stepinfo
%       PeakTime          (s)         from stepinfo
%       SteadyStateError  (units)     tar_amplitude - act_steady_state
%
%   Required inputs:
%       d                  struct returned by load() on a .mat log
%                          produced by bin2mat.py
%       experiment         "speed" (surge, m/s) or "yaw" (yaw rate, rad/s)
%       t0                 reference timestamp; plot times are
%                          d.PID*_timestamp - t0 (caller's elapsed-time origin)
%       t_step_start       elapsed seconds at step onset
%       t_step_end         elapsed seconds when response has settled
%       tar_amplitude      observed amplitude of the target (setpoint)
%       act_steady_state   observed steady-state value of the actual output
%
%   Optional name-value arguments (any order):
%       X                  plot lead-in: figure starts X seconds before
%                          t_step_start (default 2.0 s)
%       textbox_fontsize   font size for the corner metrics / gains boxes
%                          and their accompanying legends (default 9 pt)
%
%   Plots a 2x1 figure:
%       (211) PID Tar / Act with target & steady-state reference lines.
%             A legend-style text box in the corner reports the metrics.
%       (212) PID P, I, D, FF terms and total (P + I + D + FF).
%             A legend-style text box in the corner reports the PID gains.
%   Channel = PIDA_* (params ATC_SPEED_*) for speed,
%             PIDS_* (params ATC_STR_RAT_*) for yaw-rate.
arguments
    d                          (1,1) struct
    experiment                 (1,1) string
    t0                         (1,1) double
    t_step_start               (1,1) double
    t_step_end                 (1,1) double
    tar_amplitude              (1,1) double
    act_steady_state           (1,1) double
    options.X                  (1,1) double = 2.0
    options.textbox_fontsize   (1,1) double = 9
end

X                = options.X;
textbox_fontsize = options.textbox_fontsize;


% Elapsed-time vectors from raw log timestamps
t_pids = d.PIDS_timestamp - t0;
t_pida = d.PIDA_timestamp - t0;

t_plot_start = t_step_start - X;

% PID internals over the plot window
%   PIDA_* = throttle/speed PID, PIDS_* = steering/yaw-rate PID
if experiment == "speed"
    pidPrefix   = "PIDA";
    paramPrefix = "ATC_SPEED";
    chanStr     = "Speed";
    unitStr     = "m/s";
    rcouChan    = "RCOU_C3";
    ctrlLabel   = "RCOU\_C3 (throttle ESC, norm.)";
    mask_pid = t_pida >= t_plot_start & t_pida <= t_step_end;
    t_pid    = t_pida(mask_pid) - t_step_start;
    pid_tar  = d.PIDA_Tar(mask_pid);
    pid_act  = d.PIDA_Act(mask_pid);
    pid_P    = d.PIDA_P(mask_pid);
    pid_I    = d.PIDA_I(mask_pid);
    pid_D    = d.PIDA_D(mask_pid);
    pid_FF   = d.PIDA_FF(mask_pid);
else  % "yaw"
    pidPrefix   = "PIDS";
    paramPrefix = "ATC_STR_RAT";
    chanStr     = "Yaw rate";
    unitStr     = "rad/s";
    rcouChan    = "RCOU_C1";
    ctrlLabel   = "RCOU\_C1 (rudder, norm.)";
    mask_pid = t_pids >= t_plot_start & t_pids <= t_step_end;
    t_pid    = t_pids(mask_pid) - t_step_start;
    pid_tar  = d.PIDS_Tar(mask_pid);
    pid_act  = d.PIDS_Act(mask_pid);
    pid_P    = d.PIDS_P(mask_pid);
    pid_I    = d.PIDS_I(mask_pid);
    pid_D    = d.PIDS_D(mask_pid);
    pid_FF   = d.PIDS_FF(mask_pid);
end
pid_out = pid_P + pid_I + pid_D + pid_FF;

% Control effort sent to the actuator (PWM -> normalized [-1, +1])
t_rcou_all = d.RCOU_timestamp - t0;
mask_rcou  = t_rcou_all >= t_plot_start & t_rcou_all <= t_step_end;
t_rcou     = t_rcou_all(mask_rcou) - t_step_start;
ctrl_norm  = normalize_pwm(d.(rcouChan)(mask_rcou), 1500, 1900, 1100);

% Step metrics over the post-onset portion
% (stepinfo signature: stepinfo(y, t, yfinal) -- y first, then t.)
tmask = t_pid >= 0;
S_raw = stepinfo(pid_act(tmask), t_pid(tmask), act_steady_state);

S = struct();
S.RiseTime         = S_raw.RiseTime;
S.SettlingTime     = S_raw.SettlingTime;
S.Overshoot        = S_raw.Overshoot;
S.Peak             = S_raw.Peak;
S.PeakTime         = S_raw.PeakTime;
S.SteadyStateError = tar_amplitude - act_steady_state;

% PID gains from the params struct
P_gain  = d.params.(sprintf("%s_P",  paramPrefix));
I_gain  = d.params.(sprintf("%s_I",  paramPrefix));
D_gain  = d.params.(sprintf("%s_D",  paramPrefix));
FF_gain = d.params.(sprintf("%s_FF", paramPrefix));

clf();

% (211) Tar / Act with reference lines and a legend-style metrics text box
ax1 = subplot(2,1,1);
hold on;
plot(t_pid, pid_tar, "DisplayName", sprintf("%s\\_Tar", pidPrefix));
plot(t_pid, pid_act,  "DisplayName", sprintf("%s\\_Act", pidPrefix));
xline(ax1, 0, ":", "DisplayName", "Step Onset", ...
    "LabelVerticalAlignment", "bottom", "LabelHorizontalAlignment", "center");
yline(ax1, act_steady_state, ":", "DisplayName", "Act(ual) Steady State");
yline(ax1, tar_amplitude,    ":", "DisplayName", "Tar(get) Amplitude");
hold off;
ylabel(sprintf("%s (%s)", chanStr, unitStr));
title(sprintf("%s PID Internals - Step Window", chanStr), "Interpreter", "none");
l1 = legend("Location", "northeast","FontSize",textbox_fontsize);
grid on;

metrics_text = sprintf([ ...
    'Step Response Metrics\n' ...
    '  Rise time          :%10.3f s    \n' ...
    '  Settling time      :%10.3f s    \n' ...
    '  Overshoot          :%10.3f pct  \n' ...
    '  Peak               :%10.3f %s  \n' ...
    '  Peak time          :%10.3f s    \n' ...
    '  Steady-state error :%10.3f %s  '], ...
    S.RiseTime, S.SettlingTime, S.Overshoot, ...
    S.Peak, unitStr, S.PeakTime, ...
    S.SteadyStateError, unitStr);
text(ax1, 0.98, 0.05, metrics_text, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "right", ...
    "VerticalAlignment", "bottom", ...
    "FontName", "FixedWidth", "FontSize", textbox_fontsize, ...
    "BackgroundColor", "white", "EdgeColor", "black", "Margin", 4);

% (212) Term breakdown with a legend-style PID-gains text box
ax2 = subplot(2,1,2);
hold on;
plot(t_pid,  pid_P,       "DisplayName", sprintf("%s\\_P",          pidPrefix));
plot(t_pid,  pid_I,       "DisplayName", sprintf("%s\\_I",          pidPrefix));
plot(t_pid,  pid_D,       "DisplayName", sprintf("%s\\_D",          pidPrefix));
plot(t_pid,  pid_FF,      "DisplayName", sprintf("%s\\_FF",         pidPrefix));
plot(t_pid,  pid_out,    "DisplayName", sprintf("%s\\_(P+I+D+FF)", pidPrefix));
plot(t_rcou, ctrl_norm, "--",  "DisplayName", ctrlLabel);
hold off;
ylabel("PID Contributions");
xlabel("Time (s) - relative to step onset");
l2 = legend("Location", "northeast","FontSize",textbox_fontsize);
grid on;

gains_text = sprintf([ ...
    'PID Gains (%s_*)\n' ...
    'P :\t %.2f\n' ...
    'I :\t %.2f\n' ...
    'D :\t %.2f\n' ...
    'FF:\t %.2f'], ...
    paramPrefix, P_gain, I_gain, D_gain, FF_gain);
text(ax2, 0.98, 0.05, gains_text, ...
    "Units", "normalized", ...
    "HorizontalAlignment", "right", ...
    "VerticalAlignment", "bottom", ...
    "FontName", "FixedWidth", "FontSize", textbox_fontsize, ...
    "BackgroundColor", "white", "EdgeColor", "black", "Margin", 4,"Interpreter","none");

linkaxes([ax1, ax2], "x");

end
