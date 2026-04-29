% sim_speed_loop.m  –  Linear TF simulation of ArduRover speed controller
%
% Implements the speed (surge) loop as a block diagram of transfer functions.
% All nonlinear elements are linearised:
%   Acceleration limit  →  first-order low-pass  F_a(s) = wa/(s+wa)
%   Throttle baseline   →  proportional gain      K_base
%   Anti-windup IMAX    →  omitted (assume unsaturated)
%   Dmod / PD scale     →  combined gain          K_pd
%
% Controller structure (from filtered reference V_r = F_a*FLTT*R):
%   Feedforward:  U_ff = (K_base  +  K_DFF*s) * V_r
%   Feedback:     U_fb = (K_P*F_e +  K_I/s  +  K_D*s*F_d) * K_pd * E
%   Error:        E    = V_r - Y
%   Plant:        Y    = G_v * (U_ff + U_fb)
%
% Closed-loop TF (derived below):
%   Let C_FF = K_base + K_DFF*s          (acts on V_r)
%       C_FB = K_pd*(K_P*F_e + K_D*s*F_d) + K_I/s   (acts on E)
%   T(s) = G_v * F_in * (C_FF + C_FB) / (1 + G_v * C_FB)
%
% Run from latex/pid_article/ or add this folder to the MATLAB path.

%% ── Plant ───────────────────────────────────────────────────────────────────
K_v   = 2.2;     % surge DC gain  (m/s per unit throttle)
tau_v = 1.5;     % surge time constant (s)
G_v   = tf(K_v, [tau_v 1]);

%% ── Filter cutoff frequencies (rad/s) ───────────────────────────────────────
% Corresponding ArduRover parameters shown in comments.
w_a    = 2.0;    % acceleration limit approx  (ATC_ACCEL_MAX / cruise speed)
w_fltt = 3.0;    % target speed filter         _FLTT
w_flte = 3.0;    % error filter                _FLTE
w_fltd = 10.0;   % D-term filter               _FLTD

%% ── Controller gains ─────────────────────────────────────────────────────────
K_P   = 0.5;     % _P
K_I   = 0.2;     % _I
K_D   = 0.02;    % _D
K_pd  = 1.0;     % PD scale (Dmod treated as unity in linear model)

% Feedforward: use K_base OR K_FF — set the other to zero.
K_base = 0.45;   % throttle baseline (linearised slope at operating point)
K_FF   = 0.0;    % proportional speed feedforward  _FF  (redundant with K_base)
K_DFF  = 0.05;   % derivative speed feedforward    _DFF

%% ── Build transfer functions ─────────────────────────────────────────────────
s = tf('s');

F_a   = tf(w_a,    [1  w_a   ]);   % acceleration limit (first-order approx)
FLTT  = tf(w_fltt, [1  w_fltt]);   % target speed filter
FLTE  = tf(w_flte, [1  w_flte]);   % error filter
FLTD  = tf(w_fltd, [1  w_fltd]);   % D-term filter
F_in  = F_a * FLTT;                % combined input shaping  R → V_r

% Feedback controller C_FB(s)  [acts on error E]
C_P  = K_pd * K_P * FLTE;
C_I  = K_I / s;
C_D  = K_pd * K_D * s * FLTD;
C_FB = C_P + C_I + C_D;

% Feedforward C_FF(s)  [acts on filtered reference V_r]
% Note: K_DFF*s is improper alone; proper when pre-multiplied by F_in.
C_FF = (K_base + K_FF) + K_DFF * s;

%% ── Closed-loop transfer function R(s) → Y(s) ───────────────────────────────
%
%  Derivation:
%    U = C_FF*V_r + C_FB*(V_r - Y)  =  (C_FF+C_FB)*F_in*R - C_FB*Y
%    Y = G_v*U
%    => T = G_v * F_in * (C_FF + C_FB) / (1 + G_v*C_FB)
%
%  Use sensitivity S = 1/(1+G_v*C_FB) to avoid explicit division of TF objects.
%
S = feedback(1, G_v * C_FB);                        % sensitivity function
T = minreal(G_v * F_in * (C_FF + C_FB) * S);        % closed-loop  R → Y

%% ── Step response ────────────────────────────────────────────────────────────
t  = 0:0.02:20;
y  = step(T, t);

figure(1);  clf;
hold on;  box on;  grid on;
plot(t, ones(size(t)), 'k--', 'HandleVisibility','off');
plot(t, y, 'Color',[0.15 0.35 0.75]);
xlabel('Time (s)',         'FontSize',10);
ylabel('Speed (m/s)',      'FontSize',10);
title('Speed loop — closed-loop step response', 'FontSize',10);
xlim([0 20]);
set(gca, 'FontSize',10);

%% ── Loop gain: gain and phase margins ────────────────────────────────────────
L = G_v * C_FB;   % open-loop transfer function (loop gain)

figure(2);  clf;
margin(L);
title('Speed loop — loop gain margins', 'FontSize',10);

%% ── Sensitivity and complementary sensitivity ────────────────────────────────
T_comp = 1 - S;   % complementary sensitivity  (= L/(1+L))

figure(3);  clf;
bodemag(S, T_comp);
legend('S (sensitivity)', 'T (comp. sensitivity)', ...
    'Interpreter','tex', 'FontSize',9, 'Location','southwest');
title('Speed loop — sensitivity functions', 'FontSize',10);
grid on;
