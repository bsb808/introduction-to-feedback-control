

function plot_response(d, t0, flabel, options)
arguments
    d                          (1,1) struct
    t0                         (1,1) double
    flabel (1,1) string
    options.textbox_fontsize   (1,1) double = 9
end


textbox_fontsize = options.textbox_fontsize;
ax1 = subplot(211);
plot(d.PIDA_timestamp-t0, d.PIDA_Tar,  "DisplayName", "PIDA\_Tar (setpoint/cmd)");
hold on;
plot(d.PIDA_timestamp-t0, d.PIDA_Act,   "DisplayName", "PIDA\_Act (actual)");
hold off;
ylabel("Speed (m/s)");
legend("Location", "best");
title(sprintf("Speed Loop (PIDA) <%s>", flabel), "Interpreter", "none");
grid on;

% Steering = PIDS
ax2 = subplot(212);
plot(d.PIDS_timestamp-t0, d.PIDS_Tar,  "DisplayName", "PIDS\_Tar (setpoint/cmd)");
hold on;
plot(d.PIDS_timestamp-t0, d.PIDS_Act,   "DisplayName", "PIDS\_Act (actual)");
hold off;
ylabel("Speed (m/s)");
legend("Location", "best");
title(sprintf("Steering Loop (PIDS) <%s>", flabel), "Interpreter", "none");
grid on;
linkaxes([ax1, ax2], "x");

end