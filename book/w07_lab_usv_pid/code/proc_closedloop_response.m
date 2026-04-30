%% USV Closed-Loop Step Response (ACRO Mode)
% Visualize surge and yaw-rate step responses with PID control.
%
% Signals:
%   Surge:    THR_DesSpeed     — speed setpoint [m/s]
%             GPS_Spd          — measured speed [m/s]
%             RCOU_C3          — throttle command [PWM] -> normalized [-1, +1]
%
%   Yaw rate: STER_DesTurnRate — yaw-rate setpoint [rad/s]
%             STER_TurnRate    — measured yaw rate [rad/s]
%             RCOU_C1          — rudder command [PWM] -> normalized [-1, +1]

clear;
%close all;

% ── Load — CHANGE TO TARGET MAT FILE ─────────────────────────────────────────
% Linux/Mac path
% fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000006.BIN_20260429_193409.mat";
%fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000007.BIN_20260429_194748.mat";
fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000012.BIN_20260429_200429.mat";
fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000012.BIN_20260429_200014.mat";


fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000017.BIN_20260429_200911.mat";

% Yaw rate response: 
% Default CRUISE speeed and throttle
% Default PID
% Default rate limiters on
%fname = "/data/Downloads/42926_boat_tests_2801/LOGS/00000016.BIN_20260429_200517.mat";

% Windows path
% fname = "C:\Users\bsb\Downloads\00000001.BIN.mat";

fprintf('Loading %s...\n', fname);
d = load(fname);

%% ── File label for plot titles ───────────────────────────────────────────────
[dirpath, name, ext] = fileparts(fname);
[~, lastDir] = fileparts(dirpath);
fileLabel = fullfile(lastDir, sprintf("%s.%s", name, ext));

%% ── Convert timestamps to datetime (UTC) ────────────────────────────────────
posix2dt = @(t) datetime(t, 'ConvertFrom', 'posixtime', 'TimeZone', 'America/Los_Angeles');

t_thr  = posix2dt(d.THR_timestamp);
t_gps  = posix2dt(d.GPS_timestamp);
t_ster = posix2dt(d.STER_timestamp);
t_rcou = posix2dt(d.RCOU_timestamp);

%% ── PWM normalization ────────────────────────────────────────────────────────
% Bidirectional: maps PWM 1100-1900 to [-1, +1]
% Adjust inmax/inmin to match your vehicle's .params (RC3_MAX, RC1_MAX, etc.)
inzero = 1500;
inmax  = 1900;
inmin  = 1100;

pwm_norm = @(pwm) normalize_pwm(pwm, inzero, inmax, inmin);

throttle_norm = pwm_norm(d.RCOU_C3);   % surge control effort
rudder_norm   = pwm_norm(d.RCOU_C1);   % yaw control effort

%% ── Surge step response ──────────────────────────────────────────────────────
figure(1);
clf();

ax1 = subplot(211);
hold on;
plot(t_thr,  d.THR_DesSpeed, 'b--', 'DisplayName', 'Setpoint');
plot(t_gps,  d.GPS_Spd,      'r-',  'DisplayName', 'Measured (GPS)');
hold off;
ylabel('Speed (m/s)');
legend('Location', 'best');
title(sprintf("Closed-Loop Surge Step Response - %s", fileLabel), 'Interpreter', 'none');
grid on;

ax2 = subplot(212);
plot(t_rcou, throttle_norm, 'k-', 'DisplayName', 'Throttle');
ylabel('Throttle effort (norm.)');
ylim([-1.05, 1.05]);
xlabel('Time (s)');
legend('Location', 'best');
grid on;

linkaxes([ax1, ax2], 'x');

%% ── Yaw-rate step response ───────────────────────────────────────────────────
figure(2);
clf();

ax1 = subplot(211);
hold on;
plot(t_ster, d.STER_DesTurnRate, 'b--', 'DisplayName', 'Setpoint');
plot(t_ster, d.STER_TurnRate,    'r-',  'DisplayName', 'Measured');
hold off;
ylabel('Yaw rate (rad/s)');
legend('Location', 'best');
title(sprintf("Closed-Loop Yaw-Rate Step Response - %s", fileLabel), 'Interpreter', 'none');
grid on;

ax2 = subplot(212);
plot(t_rcou, rudder_norm, 'k-', 'DisplayName', 'Rudder');
ylabel('Rudder effort (norm.)');
ylim([-1.05, 1.05]);
xlabel('Time (s)');
legend('Location', 'best');
grid on;

linkaxes([ax1, ax2], 'x');

%% ── PID parameters ───────────────────────────────────────────────────────────
if isfield(d, 'params')
    p = d.params;
    fprintf('\n--- Surge speed PID (ATC_SPEED_*) ---\n');
    fprintf('  P:         %g\n', p.ATC_SPEED_P);
    fprintf('  I:         %g\n', p.ATC_SPEED_I);
    fprintf('  D:         %g\n', p.ATC_SPEED_D);
    fprintf('  FF:        %g\n', p.ATC_SPEED_FF);
    fprintf('  FLTE:      %g Hz\n', p.ATC_SPEED_FLTE);
    fprintf('  ACCEL_MAX: %g m/s^2  (0 = unlimited)\n', p.ATC_ACCEL_MAX);

    fprintf('\n--- Yaw-rate PID (ATC_STR_RAT_*) ---\n');
    fprintf('  P:        %g\n', p.ATC_STR_RAT_P);
    fprintf('  I:        %g\n', p.ATC_STR_RAT_I);
    fprintf('  D:        %g\n', p.ATC_STR_RAT_D);
    fprintf('  FF:       %g\n', p.ATC_STR_RAT_FF);
    fprintf('  FLTE:     %g Hz\n', p.ATC_STR_RAT_FLTE);
    fprintf('  ACC_MAX:  %g deg/s^2  (0 = unlimited)\n', p.ATC_STR_ACC_MAX);
    fprintf('  RAT_MAX:  %g deg/s\n', p.ATC_STR_RAT_MAX);
    fprintf('\n');
else
    fprintf('No params struct found — reprocess .BIN with updated bin2mat.py\n');
end

%% ── Sample rates ─────────────────────────────────────────────────────────────
fprintf('THR  sample rate: %.1f Hz\n', 1/mean(diff(d.THR_timestamp)));
fprintf('GPS  sample rate: %.1f Hz\n', 1/mean(diff(d.GPS_timestamp)));
fprintf('STER sample rate: %.1f Hz\n', 1/mean(diff(d.STER_timestamp)));
fprintf('RCOU sample rate: %.1f Hz\n', 1/mean(diff(d.RCOU_timestamp)));

%% ── Helper ───────────────────────────────────────────────────────────────────
function out = normalize_pwm(pwm, inzero, inmax, inmin)
    out = zeros(size(pwm));
    pos = pwm >= inzero;
    out( pos) = (pwm( pos) - inzero) / (inmax - inzero);
    out(~pos) = (pwm(~pos) - inzero) / (inzero - inmin);
end
