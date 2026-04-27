%% USV Open-Loop Surge Step Response
% System identification of surge (forward velocity) model
% Input:  RCOU_C1 — throttle command to ESC (%)
% Output: GPS_Spd — ground speed (m/s)

clear; 
%close all;

% ── Load CHANGE TO TARGET MAT FILE! ─────────────────────────────────────────────────────────
% Linux/Mac path
fname = "/data/Downloads/step_resp_example.BIN.mat";
% Windows path
% fname = 'C:\Users\bsb\Downloads\00000010.BIN.mat';
% fname = "C:\Users\bsb\Downloads\USVData_20260415\USVData_20260415\cyborg\00000005.BIN.mat";
% fname = "C:\Users\bsb\Downloads\USVData_20260415\USVData_20260415\blackpearl\00000009.BIN.mat";
% fname = "C:\Users\bsb\Downloads\USVData_20260415\USVData_20260415\blackpearl\00000009.BIN.mat";
% fname = "C:\Users\bsb\Downloads\USVData_20260415\USVData_20260415\Team3\00000003.BIN.mat";

fprintf('Loading %s...\n', fname);
d = load(fname);


%% ── Time bases (zero-referenced) ─────────────────────────────────────────
t_rcou  = d.RCOU_timestamp;
t_gps   = d.GPS_timestamp;

% ── Plot Speed Response ─────────────────────────────────────────────────────────────────
figure();
clf()
%yyaxis left
ax1 = subplot(211);
plot(d.RCOU_timestamp, d.RCOU_C3, 'b-', 'LineWidth', 1.5, ...
     'DisplayName', 'Throttle Command');
ylabel('Throttle Command (PWM)');
grid on;
% Extract last two path elements (directory and filename) from full path fname
[dirpath, name, ext] = fileparts(fname);
[~, lastDir] = fileparts(dirpath);
lastTwo = fullfile(lastDir,sprintf("%s.%s",name,ext));
fprintf('Last two path elements: %s\n', lastTwo);
title(sprintf("Open-Loop Surge Step Response — %s",lastTwo));

ax2 = subplot(212);
%yyaxis right
plot(d.GPS_timestamp, d.GPS_Spd, 'r-', 'LineWidth', 1.5, ...
     'DisplayName', 'Ground Speed (m/s)');
ylabel('Ground Speed (m/s)');

xlabel('Time (s)');
grid on;

% Link the x-axes of both subplots
linkaxes([ax1, ax2], 'x'); 


%% Yaw-Rate Rtep Response
% USV Open-Loop Yaw Step Response
% System identification of yaw rate model
% Input:  RCOU_C3 — rudder command to servo (%)
% Output: IMU_GyrZ — yaw rate (rad/s converted to deg/s)


% ── Plot ─────────────────────────────────────────────────────────────────
figure()
clf()
ax1 = subplot(211);
plot(d.RCOU_timestamp, d.RCOU_C1, 'b-', 'LineWidth', 1.5, ...
     'DisplayName', 'Rudder Command (%)');
ylabel('Rudder Command (PWM)');
%title('Open-Loop Yaw Step Response — Rudder Command vs Yaw Rate');
title(sprintf("Open-Loop Yaw Step Response — %s",lastTwo));

grid on;

ax2 = subplot(212);
plot(d.IMU_timestamp, d.IMU_GyrZ * (180/pi), 'r-', 'LineWidth', 1.5, ...
     'DisplayName', 'Yaw Rate (deg/s)');
ylabel('Yaw Rate (deg/s)');
xlabel('Time (s)');
legend('Location', 'best');
grid on;
linkaxes([ax1, ax2], 'x'); 

fprintf('GPS sample rate: %.1f Hz\n', ...
         1/mean(diff(t_gps)));
fprintf('RCOU sample rate: %.1f Hz\n', ...
        1/mean(diff(t_rcou)));

%% Save just the pertinent data

% fields = ["IMU_timestamp", "IMU_GyrZ", ...
%     "RCOU_timestamp", "RCOU_C1", ...
%     "RCOU_C3", ...
%     "GPS_timestamp", "GPS_Spd"];
% 
% for i = 1:numel(fields)
%     f = fields(i);
%     if isfield(d, f)
%         dd.(f) = d.(f);
%     end
% end
% 
% [fpath, fname_base, ext] = fileparts(fname);
% fname_proc = fullfile(fpath, sprintf("%s.proc%s",fname_base, ext));
% 
% fprintf("Saved selected data as %s\n", fname_proc);
% save(fname_proc, "dd");