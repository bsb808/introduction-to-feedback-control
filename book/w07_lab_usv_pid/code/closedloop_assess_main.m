
clear;

set(0, 'DefaultFigureWindowStyle', 'normal')
set(groot, 'defaultAxesFontName','Helvetica', 'defaultAxesFontSize',10);

export_figs = true;
if export_figs
    close("all");
end

% For manually looking through logs
matfiles = dir(fullfile("/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_baseline3/", "*.mat"));
exp = struct('label', {}, 'fname', {}, 'fdir', {}, 'experiment', {}, 't_step_start', {}, 't_step_end', {}, 'tar_amplitude', {}, 'act_steady_state', {});
% Manually increment the index
%exp(1).fname = matfiles(5).name;

exp(1).label = "base_speed";
exp(1).fname = "00000005.BIN_20260506_213337.mat";
exp(1).fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_baseline3/";
exp(1).experiment = "speed";
exp(1).t_step_start = 4.82;    
exp(1).t_step_end   = 25.33;  
exp(1).tar_amplitude = 0.89;  
exp(1).act_steady_state = 0.89; 


exp(end+1).label = "base_yaw";
exp(end).fname = "00000015.BIN_20260506_222221.mat";
exp(end).fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_baseline3/";
exp(end).experiment = "yaw";
exp(end).t_step_start = 29.9789;    
exp(end).t_step_end   = 38.8;  
exp(end).tar_amplitude = 2.0944;  
exp(end).act_steady_state = 0.7930; 

% This is a repeat - hack to illustrate integrator windup in heading
% without feedforward.
exp(end+1).label = "base_yaw_windup";
exp(end).fname = "00000015.BIN_20260506_222221.mat";
exp(end).fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_baseline3/";
exp(end).experiment = "yaw";
exp(end).t_step_start = 0;    
exp(end).t_step_end   = 53;  
exp(end).tar_amplitude = 2.0944;  
exp(end).act_steady_state = 0.7930; 

exp(end+1).label = "ff_speed";
exp(end).fname = "00000011.BIN_20260506_223549.mat";
exp(end).fdir = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
exp(end).experiment = "speed";
exp(end).t_step_start = 4.02;    
exp(end).t_step_end   = 15.24;  
exp(end).tar_amplitude = 1.95;  
exp(end).act_steady_state = 1.97; 

% FF, Yaw
exp(end+1).label        = "ff_yaw";
exp(end).fname          = "00000013.BIN_20260506_223627.mat";
exp(end).fdir           = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
exp(end).experiment     = "yaw";
exp(end).t_step_start   = 21.52;
exp(end).t_step_end     = 30;
exp(end).tar_amplitude  = -2.1;
exp(end).act_steady_state = -0.669;

% Tuned, Speed
exp(end+1).label        = "tuned_speed";
exp(end).fname          = "00000015.BIN_20260506_223900.mat";
exp(end).fdir           = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
exp(end).experiment     = "speed";
exp(end).t_step_start   = 3.28;
exp(end).t_step_end     = 14.0;
exp(end).tar_amplitude  = 2.15;
exp(end).act_steady_state = 1.99;

% Tuned, Yaw
exp(end+1).label        = "tuned_yaw";
exp(end).fname          = "00000017.BIN_20260506_223937.mat";
exp(end).fdir           = "/home/bsb/WorkingCopies/me2801/data/2026_05_06_lab2_proto/2026_05_06_tuning/";
exp(end).experiment     = "yaw";
exp(end).t_step_start   = 19.879;
exp(end).t_step_end     = 27.4;
exp(end).tar_amplitude  = -2.0944;
exp(end).act_steady_state = -0.7333;

for ii = 1:length(exp)
    ff = fullfile(exp(ii).fdir, exp(ii).fname);
    d = load(ff);
    [dirpath, name, ext] = fileparts(ff);
    [~, lastDir] = fileparts(dirpath);
    flabel = fullfile(lastDir, sprintf("%s.%s", name, ext));


    %% Print the pertinent controller parameters
    p = d.params;
    fprintf("\n--- Surge speed PID (ATC_SPEED_*) ---\n");
    fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
        p.ATC_SPEED_P, p.ATC_SPEED_I, p.ATC_SPEED_D, p.ATC_SPEED_FF);
    fprintf("\n--- Yaw-rate PID (ATC_STR_RAT_*) ---\n");
    fprintf("  P: %g    I: %g    D: %g    FF: %g\n", ...
        p.ATC_STR_RAT_P, p.ATC_STR_RAT_I, p.ATC_STR_RAT_D, p.ATC_STR_RAT_FF);


    %% Plot the full response for both controllers.
    t0 = min([d.PIDA_timestamp(1), d.PIDS_timestamp(1)]);

    f1 = figure(2*ii-1); 
    plot_response(d, t0, flabel, textbox_fontsize=8)
    if export_figs
        set(f1, 'Units','inches', 'Position',[1 1 8 5]);

        exportgraphics(f1, sprintf("images/%s_response.pdf",exp(ii).label),...
            'ContentType','vector');
        textbox_fontsize = 9;
        plot_response(d, t0, flabel, textbox_fontsize=8)
        exportgraphics(f1, sprintf("images/%s_response.png",exp(ii).label),...
            'Resolution', 300);
    end

    f2 = figure(2*ii);
    S(ii) = step_response_metrics(d, exp(ii).experiment, t0, exp(ii).t_step_start, exp(ii).t_step_end, ...
                      exp(ii).tar_amplitude, exp(ii).act_steady_state, ...
                      textbox_fontsize=7);
    % CLAUDE: Create a structure that includes the label, controller params
    % (P, I, D, FF), risetime, settlingtime, peak, peaktime and
    % steadystateerror
    
    if export_figs
        set(f2, 'Units','inches', 'Position',[1 1 8 6]);
        
        exportgraphics(f2, sprintf("images/%s_pids.pdf",exp(ii).label),...
            'ContentType','vector');
           step_response_metrics(d, exp(ii).experiment, t0, exp(ii).t_step_start, exp(ii).t_step_end, ...
                          exp(ii).tar_amplitude, exp(ii).act_steady_state, ...
                          textbox_fontsize=6);
        exportgraphics(f2, sprintf("images/%s_pids.png",exp(ii).label),...
            'Resolution', 300);
    end
end