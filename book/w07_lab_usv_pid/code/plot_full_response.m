function log = plot_full_response(fname, experiment)
% PLOT_FULL_RESPONSE  Print PID parameters and plot the full timeseries.
%   log = plot_full_response(fname, experiment)
%
%   Inputs:
%       fname       path to ArduPilot .mat log produced by bin2mat.py
%       experiment  "speed" (surge, m/s) or "yaw" (yaw rate, rad/s)
%
%   Outputs:
%       log         struct containing the data plotted (for further analysis)
%   Plots:
%       Figure: setpoint, measured response, and control effort.
%       Figure: (If logs present) PID controller internals (Tar/Act, P/I/D/FF, total output).
arguments
    fname      (1,1) string
    experiment (1,1) string
end

log = load_and_prep(fname);
print_pid_params(log.d);

%if experiment == "speed"
    figure(); clf();
    ax1 = subplot(211);
    hold on;
    plot(log.t_thr, log.d.THR_DesSpeed, "b--", "DisplayName", "Setpoint");
    plot(log.t_gps, log.d.GPS_Spd,      "r-",  "DisplayName", "Measured (GPS)");
    hold off;
    ylabel("Speed (m/s)");
    legend("Location", "best");
    title(sprintf("Surge Step Response - %s", log.fileLabel), "Interpreter", "none");
    grid on;
    ax2 = subplot(212);
    plot(log.t_rcou, log.throttle_norm, "k-", "DisplayName", "Throttle");
    ylabel("Throttle effort (norm.)");
    ylim([-1.05, 1.05]);
    xlabel("Elapsed time (s)");
    legend("Location", "best");
    grid on;
    linkaxes([ax1, ax2], "x");

    if log.has_pids
        figure(); clf();
        ax1 = subplot(311);
        hold on;
        plot(log.t_pids, log.d.PIDS_Tar, "b--", "DisplayName", "Target");
        plot(log.t_pids, log.d.PIDS_Act, "r-",  "DisplayName", "Actual");
        hold off;
        ylabel("Speed (m/s)");
        legend("Location", "best");
        title(sprintf("Speed PID Internals - %s", log.fileLabel), "Interpreter", "none");
        grid on;
        ax2 = subplot(312);
        hold on;
        plot(log.t_pids, log.d.PIDS_P,  "b-",  "DisplayName", "P");
        plot(log.t_pids, log.d.PIDS_I,  "g-",  "DisplayName", "I");
        plot(log.t_pids, log.d.PIDS_D,  "r-",  "DisplayName", "D");
        plot(log.t_pids, log.d.PIDS_FF, "m--", "DisplayName", "FF");
        hold off;
        ylabel("PID terms");
        legend("Location", "best");
        grid on;
        ax3 = subplot(313);
        plot(log.t_pids, log.d.PIDS_P + log.d.PIDS_I + log.d.PIDS_D + log.d.PIDS_FF, ...
            "k-", "DisplayName", "Output");
        ylabel("PID output");
        xlabel("Elapsed time (s)");
        legend("Location", "best");
        grid on;
        linkaxes([ax1, ax2, ax3], "x");
    else
        fprintf("PIDS messages not found in log - no speed PID internals plot.\n");
    end
%else
    figure(); clf();
    ax1 = subplot(211);
    hold on;
    plot(log.t_ster, log.d.STER_DesTurnRate, "b--", "DisplayName", "Setpoint");
    plot(log.t_ster, log.d.STER_TurnRate,    "r-",  "DisplayName", "Measured");
    hold off;
    ylabel("Yaw rate (rad/s)");
    legend("Location", "best");
    title(sprintf("Yaw-Rate Step Response - %s", log.fileLabel), "Interpreter", "none");
    grid on;
    ax2 = subplot(212);
    plot(log.t_rcou, log.rudder_norm, "k-", "DisplayName", "Rudder");
    ylabel("Rudder effort (norm.)");
    ylim([-1.05, 1.05]);
    xlabel("Elapsed time (s)");
    legend("Location", "best");
    grid on;
    linkaxes([ax1, ax2], "x");

    if log.has_pida
        figure(); clf();
        ax1 = subplot(311);
        hold on;
        plot(log.t_pida, log.d.PIDA_Tar, "b--", "DisplayName", "Target");
        plot(log.t_pida, log.d.PIDA_Act, "r-",  "DisplayName", "Actual");
        hold off;
        ylabel("Yaw rate (rad/s)");
        legend("Location", "best");
        title(sprintf("Yaw-Rate PID Internals - %s", log.fileLabel), "Interpreter", "none");
        grid on;
        ax2 = subplot(312);
        hold on;
        plot(log.t_pida, log.d.PIDA_P,  "b-",  "DisplayName", "P");
        plot(log.t_pida, log.d.PIDA_I,  "g-",  "DisplayName", "I");
        plot(log.t_pida, log.d.PIDA_D,  "r-",  "DisplayName", "D");
        plot(log.t_pida, log.d.PIDA_FF, "m--", "DisplayName", "FF");
        hold off;
        ylabel("PID terms");
        legend("Location", "best");
        grid on;
        ax3 = subplot(313);
        plot(log.t_pida, log.d.PIDA_P + log.d.PIDA_I + log.d.PIDA_D + log.d.PIDA_FF, ...
            "k-", "DisplayName", "Output");
        ylabel("PID output");
        xlabel("Elapsed time (s)");
        legend("Location", "best");
        grid on;
        linkaxes([ax1, ax2, ax3], "x");
    else
        fprintf("PIDA messages not found in log - no yaw-rate PID internals plot.\n");
    end
%end
end
