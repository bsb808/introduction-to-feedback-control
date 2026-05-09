function L = load_and_prep(fname)
% LOAD_AND_PREP  Load .mat log and compute elapsed-time vectors and normalized PWM.
%   L = load_and_prep(fname)
%
%   Returns a struct L with fields:
%     d              - the loaded log struct
%     fileLabel      - "<lastDir>/<name>.<ext>" string for plot titles
%     t_thr, t_gps,
%     t_ster, t_rcou - elapsed-time vectors (seconds from earliest message)
%     t_pids, t_pida - elapsed-time vectors for the PID log channels
%                        PIDS_* = steering (yaw-rate) PID
%                        PIDA_* = throttle (speed) PID
%                      Errors if either timestamp field is missing.
%     throttle_norm  - RCOU_C3 PWM scaled to normalized effort (-1..+1)
%     rudder_norm    - RCOU_C1 PWM scaled to normalized effort (-1..+1)
arguments
    fname (1,1) string
end

fprintf("Loading %s ...\n", fname);
L.d = load(fname);

[dirpath, name, ext] = fileparts(fname);
[~, lastDir] = fileparts(dirpath);
L.fileLabel = fullfile(lastDir, sprintf("%s.%s", name, ext));

% Elapsed seconds from the earliest message across all channels
t0 = min([L.d.THR_timestamp(1), L.d.GPS_timestamp(1), ...
          L.d.STER_timestamp(1), L.d.RCOU_timestamp(1)]);
L.t_thr  = L.d.THR_timestamp  - t0;
L.t_gps  = L.d.GPS_timestamp  - t0;
L.t_ster = L.d.STER_timestamp - t0;
L.t_rcou = L.d.RCOU_timestamp - t0;

% PID internal log messages (PIDS = steering / yaw-rate, PIDA = throttle / speed)
L.t_pids = L.d.PIDS_timestamp - t0;
L.t_pida = L.d.PIDA_timestamp - t0;

% PWM -> normalized effort (piecewise; adjust to match vehicle params)
inzero = 1500;  inmax = 1900;  inmin = 1100;
L.throttle_norm = normalize_pwm(L.d.RCOU_C3, inzero, inmax, inmin);
L.rudder_norm   = normalize_pwm(L.d.RCOU_C1, inzero, inmax, inmin);
end
