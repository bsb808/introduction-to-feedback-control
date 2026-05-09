function log = plot_speed_response(fname)
% PLOT_SPEED_RESPONSE  Print PID parameters and plot the surge-speed timeseries.
%   log = plot_speed_response(fname)
%
%   Inputs:
%       fname       path to ArduPilot .mat log produced by bin2mat.py
%
%   Outputs:
%       log         struct returned by load_and_prep (for further analysis)
%
%   Plots:
%       Figure: speed setpoint, measured (GPS), and throttle effort.
%       Figure: speed PID internals - Tar/Act, P/I/D/FF, and total
%               output P+I+D+FF (errors if PIDA_* fields are missing).
arguments
    fname (1,1) string
end

log = load_and_prep(fname);

% figure(); clf();
% ax1 = subplot(211);
% hold on;
% plot(log.t_thr, log.d.THR_DesSpeed, "b--", "DisplayName", "THR\_DesSpeed");
% plot(log.t_gps, log.d.GPS_Spd,      "r-",  "DisplayName", "GPS\_Spd");
% hold off;
% ylabel("Speed (m/s)");
% legend("Location", "best");
% title(sprintf("Surge Step Response - %s", log.fileLabel), "Interpreter", "none");
% grid on;
% ax2 = subplot(212);
% plot(log.t_rcou, log.throttle_norm, "k-", "DisplayName", "RCOU\_C3 (norm.)");
% ylabel("Throttle effort (norm.)");
% ylim([-1.05, 1.05]);
% xlabel("Elapsed time (s)");
% legend("Location", "best");
% grid on;
% linkaxes([ax1, ax2], "x");

figure(); clf();
plot(log.t_pida, log.d.PIDA_Tar, "b--", "DisplayName", "PIDA\_Tar");
hold on;
plot(log.t_pida, log.d.PIDA_Act, "r-",  "DisplayName", "PIDA\_Act");
hold off;
ylabel("Speed (m/s)");
legend("Location", "best");
title(sprintf("Speed PID Internals - %s", log.fileLabel), "Interpreter", "none");
grid on;
end
