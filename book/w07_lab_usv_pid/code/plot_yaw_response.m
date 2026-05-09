function log = plot_yaw_response(fname)
% PLOT_YAW_RESPONSE  Print PID parameters and plot the yaw-rate timeseries.
%   log = plot_yaw_response(fname)
%
%   Inputs:
%       fname       path to ArduPilot .mat log produced by bin2mat.py
%
%   Outputs:
%       log         struct returned by load_and_prep (for further analysis)
%
%   Plots:
%       Figure: yaw-rate setpoint, measured, and rudder effort.
%       Figure: yaw-rate PID internals - Tar/Act, P/I/D/FF, and total
%               output P+I+D+FF (errors if PIDS_* fields are missing).
arguments
    fname (1,1) string
end

log = load_and_prep(fname);
print_pid_params(fname);

figure(); clf();
ax1 = subplot(211);
hold on;
plot(log.t_ster, log.d.STER_DesTurnRate, "b--", "DisplayName", "STER\_DesTurnRate");
plot(log.t_ster, log.d.STER_TurnRate,    "r-",  "DisplayName", "STER\_TurnRate");
hold off;
ylabel("Yaw rate (rad/s)");
legend("Location", "best");
title(sprintf("Yaw-Rate Step Response - %s", log.fileLabel), "Interpreter", "none");
grid on;
ax2 = subplot(212);
plot(log.t_rcou, log.rudder_norm, "k-", "DisplayName", "RCOU\_C1 (norm.)");
ylabel("Rudder effort (norm.)");
ylim([-1.05, 1.05]);
xlabel("Elapsed time (s)");
legend("Location", "best");
grid on;
linkaxes([ax1, ax2], "x");

figure(); clf();
ax1 = subplot(311);
hold on;
plot(log.t_pids, log.d.PIDS_Tar, "b--", "DisplayName", "PIDS\_Tar");
plot(log.t_pids, log.d.PIDS_Act, "r-",  "DisplayName", "PIDS\_Act");
hold off;
ylabel("Yaw rate (rad/s)");
legend("Location", "best");
title(sprintf("Yaw-Rate PID Internals - %s", log.fileLabel), "Interpreter", "none");
grid on;
ax2 = subplot(312);
hold on;
plot(log.t_pids, log.d.PIDS_P,  "b-",  "DisplayName", "PIDS\_P");
plot(log.t_pids, log.d.PIDS_I,  "g-",  "DisplayName", "PIDS\_I");
plot(log.t_pids, log.d.PIDS_D,  "r-",  "DisplayName", "PIDS\_D");
plot(log.t_pids, log.d.PIDS_FF, "m--", "DisplayName", "PIDS\_FF");
hold off;
ylabel("PID terms");
legend("Location", "best");
grid on;
ax3 = subplot(313);
plot(log.t_pids, log.d.PIDS_P + log.d.PIDS_I + log.d.PIDS_D + log.d.PIDS_FF, ...
    "k-", "DisplayName", "PIDS\_(P+I+D+FF)");
ylabel("PID output");
xlabel("Elapsed time (s)");
legend("Location", "best");
grid on;
linkaxes([ax1, ax2, ax3], "x");
end
