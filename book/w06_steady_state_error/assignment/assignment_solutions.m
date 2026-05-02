% assignment_solutions.m  --  Steady-State Error Assignment verification
% ME 2801 -- Controls Engineering
%
% Run section-by-section (Ctrl+Enter or "Run Section").
% Each section verifies the analytical answers from the corresponding
% exercise in assign_steady_state_error.tex.
%
% Naming convention (matches the assignment / solution PDFs):
%   G_ol  -- open-loop (forward path) transfer function
%   G_cl  -- closed-loop transfer function
%   G_p   -- plant transfer function
%   G_r   -- yaw-heading plant (yaw-rate plant divided by s)

%% Exercise 1 -- Three test inputs (Type 0 plant)
%
% G_ol(s) = 600 / ((s+10)(s^2 + 4s + 25))
% Hand: Type 0; Kx = 600/250 = 2.4; e_step = 1/3.4 = 0.2941;
%       e_ramp = e_para = Inf

G_ol = tf(600, conv([1 10], [1 4 25]));

Kx   = dcgain(G_ol);
G_cl = feedback(G_ol, 1);
e_ss = 1 - dcgain(G_cl);

fprintf('--- Exercise 1 ---\n')
fprintf('Kx                     = %.4f  (expect 2.40)\n', Kx)
fprintf('e_step (1 - dcgain)    = %.4f  (expect 0.2941)\n', e_ss)

%% Exercise 2 -- Design a P-only velocity tracking compensator
%
% Plant:      G_p(s) = (s+5) / (s(s+8)(s+12))
% Controller: C(s)   = Kp
% Open loop:  G_ol(s) = Kp * G_p(s)
% Hand (master formula, ramp): e_ramp = 96/(5*Kp) = 0.04 => Kp = 480
% Verify all closed-loop poles are in the LHP.

G_p  = tf([1 5], conv([1 0], conv([1 8], [1 12])));
Kp   = 480;
G_ol = Kp * G_p;
G_cl = feedback(G_ol, 1);

e_ramp = 96/(5*Kp);
fprintf('\n--- Exercise 2 ---\n')
fprintf('Kp = %d, e_ramp = 96/(5*Kp) = %.4f  (expect 0.0400)\n', Kp, e_ramp)

p = pole(G_cl);
fprintf('Closed-loop poles:\n')
disp(p)
fprintf('Max real part = %.3f  (must be < 0 for stability)\n', max(real(p)))

%% Exercise 3 -- USV surge: P / PI / P+FF / PI+FF
%
% G_p(s) = 5.1 / (1.3 s + 1)
% Kp = 0.5, Ki = 0.4, Kff = 1/5.1
% Hand: e_ss = 0.282, 0, 0, 0  (in m/s for unit-step command)

K_plant = 5.1;
tau_p   = 1.3;
G_p     = tf(K_plant, [tau_p 1]);

Kp  = 0.5;
Ki  = 0.4;
Kff = 1/K_plant;

C_P  = tf(Kp, 1);
C_PI = tf([Kp Ki], [1 0]);

% Closed-loop transfer functions for the four architectures
G_cl_P    = feedback(C_P  * G_p, 1);
G_cl_PI   = feedback(C_PI * G_p, 1);
G_cl_PFF  = G_p * (C_P  + Kff) / (1 + C_P  * G_p);
G_cl_PIFF = G_p * (C_PI + Kff) / (1 + C_PI * G_p);

fprintf('\n--- Exercise 3: step DC gain = 1 means zero SSE ---\n')
fprintf('(a) P only:   G_cl(0) = %.4f, e_ss = %.4f  (expect 0.282)\n', dcgain(G_cl_P),    1-dcgain(G_cl_P))
fprintf('(b) PI:       G_cl(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(G_cl_PI),   1-dcgain(G_cl_PI))
fprintf('(c) P + FF:   G_cl(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(G_cl_PFF),  1-dcgain(G_cl_PFF))
fprintf('(d) PI + FF:  G_cl(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(G_cl_PIFF), 1-dcgain(G_cl_PIFF))

% Plot the four step responses
t = 0:0.02:8;
figure(3); clf; hold on; grid on; box on
plot(t, ones(size(t)), 'k--', 'DisplayName', 'reference')
plot(t, step(G_cl_P,    t), 'DisplayName', 'P only')
plot(t, step(G_cl_PI,   t), 'DisplayName', 'PI')
plot(t, step(G_cl_PFF,  t), 'DisplayName', 'P + FF')
plot(t, step(G_cl_PIFF, t), 'DisplayName', 'PI + FF')
xlabel('Time (s)'); ylabel('Speed y(t) (m/s)')
title('USV surge: four controller architectures (Exercise 3)')
legend('Location', 'southeast')

%% Exercise 4 -- USV yaw heading: ramp tracking design
%
% Yaw-rate plant:    G_yawrate(s) = 0.82 / (0.61 s + 1)
% Heading is the integral of yaw rate, so the heading plant adds 1/s:
%   G_r(s) = G_yawrate(s) / s = 0.82 / (s (0.61 s + 1))
% Hand (master formula): e_ss = 5/(0.82*Kr) deg for slope = 5 deg/s
%       Spec |e_ss| <= 1 deg => Kr >= 5/0.82 = 6.10

K_y       = 0.82;
tau_y     = 0.61;
G_yawrate = tf(K_y, [tau_y 1]);                    % yaw-rate plant
G_r       = tf(K_y, conv([tau_y 1], [1 0]));        % heading plant = G_yawrate / s

Kr_min = 5/K_y;
fprintf('\n--- Exercise 4 ---\n')
fprintf('Min Kr for 1-deg heading error at 5 deg/s ramp: Kr = %.3f\n', Kr_min)

% Simulate ramp response at Kr = Kr_min
Kr   = Kr_min;
G_ol = Kr * G_r;
G_cl = feedback(G_ol, 1);

t = 0:0.05:25;
r = 5 * t;                     % degrees
y = lsim(G_cl, r, t);
e = r - y';

fprintf('e_ss from simulation (last sample) = %.3f deg (expect 1.0)\n', e(end))

figure(4); clf
subplot(2,1,1)
hold on; grid on; box on
plot(t, r, 'k--', 'DisplayName', 'reference 5t')
plot(t, y,        'DisplayName', 'output')
ylabel('Heading (deg)')
title(sprintf('USV yaw heading, K_r = %.2f (Exercise 4)', Kr))
legend('Location', 'northwest')

subplot(2,1,2)
hold on; grid on; box on
plot(t, e, 'b')
yline(1, 'r--', 'spec: 1 deg')
xlabel('Time (s)'); ylabel('Tracking error (deg)')
