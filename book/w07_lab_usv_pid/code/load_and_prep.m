function L = load_and_prep(fname)
% LOAD_AND_PREP  Load .mat log and compute elapsed-time vectors and normalized PWM.
%   L = load_and_prep(fname)
%
%   Returns a struct L with fields:
%     d              - the loaded log struct
%     fileLabel      - "<lastDir>/<name>.<ext>" string for plot titles
%     t_thr, t_gps,
%     t_ster, t_rcou - elapsed-time vectors (seconds from earliest message)
%     has_pids,
%     has_pida       - logical flags for optional PID log channels
%                        PIDS_* = speed PID
%                        PIDA_* = attitude (yaw-rate) PID
%     t_pids, t_pida - elapsed-time vectors for those channels (if present)
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

% PID internal log messages (PIDS = speed, PIDA = attitude/yaw-rate)
L.has_pids = isfield(L.d, "PIDS_timestamp");
L.has_pida = isfield(L.d, "PIDA_timestamp");
if L.has_pids, L.t_pids = L.d.PIDS_timestamp - t0; end
if L.has_pida, L.t_pida = L.d.PIDA_timestamp - t0; end

% PWM -> normalized effort (piecewise; adjust to match vehicle params)
inzero = 1500;  inmax = 1900;  inmin = 1100;
L.throttle_norm = normalize_pwm(L.d.RCOU_C3, inzero, inmax, inmin);
L.rudder_norm   = normalize_pwm(L.d.RCOU_C1, inzero, inmax, inmin);
end
