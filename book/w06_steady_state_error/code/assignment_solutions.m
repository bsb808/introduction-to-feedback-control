% assignment_solutions.m  --  Steady-State Error Assignment verification
% ME 2801 -- Controls Engineering
%
% Run section-by-section (Ctrl+Enter or "Run Section").
% Each section verifies the analytical answers from the corresponding
% exercise in assignment_steady_state_error.tex.

%% Exercise 1 -- Three test inputs (Type 0 plant)
%
% G(s) = 600 / ((s+10)(s^2 + 4s + 25))
% Hand: Type 0; Kx = 600/250 = 2.4; e_step = 1/3.4 = 0.2941;
%       e_ramp = e_para = Inf

G1 = tf(600, conv([1 10], [1 4 25]));

Kx = dcgain(G1);
fprintf('--- Exercise 1 ---\n')
fprintf('Kx = %.4f  (expect 2.40)\n', Kx)

T1   = feedback(G1, 1);
ess1 = 1 - dcgain(T1);
fprintf('e_step (1 - dcgain(T)) = %.4f  (expect 0.2941)\n', ess1)

%% Exercise 2 -- Design a P-only velocity tracking compensator
%
% Plant:      G_p(s) = (s+5) / (s(s+8)(s+12))
% Controller: C(s)   = Kp
% Hand: Type 1; Kv = 5*Kp/96 = 25 => Kp = 480
% Verify all closed-loop poles are in the LHP.

Gp = tf([1 5], conv([1 0], conv([1 8], [1 12])));
Kp = 480;

Kv = 5*Kp/96;
fprintf('\n--- Exercise 2 ---\n')
fprintf('Kp = %d, Kv = %.2f  (expect 25.00)\n', Kp, Kv)
fprintf('1/Kv = %.4f          (expect 0.0400)\n', 1/Kv)

p = pole(feedback(Kp*Gp, 1));
fprintf('Closed-loop poles:\n')
disp(p)
fprintf('Max real part = %.3f  (must be < 0 for stability)\n', max(real(p)))

%% Exercise 3 -- USV surge: P / PI / P+FF / PI+FF
%
% G_p = 5.1 / (1.3 s + 1)
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

T_P    = feedback(C_P  * G_p, 1);
T_PI   = feedback(C_PI * G_p, 1);
T_PFF  = G_p * (C_P  + Kff) / (1 + C_P  * G_p);
T_PIFF = G_p * (C_PI + Kff) / (1 + C_PI * G_p);

fprintf('\n--- Exercise 3: step DC gain = 1 means zero SSE ---\n')
fprintf('(a) P only:   T(0) = %.4f, e_ss = %.4f  (expect 0.282)\n', dcgain(T_P),    1-dcgain(T_P))
fprintf('(b) PI:       T(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(T_PI),   1-dcgain(T_PI))
fprintf('(c) P + FF:   T(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(T_PFF),  1-dcgain(T_PFF))
fprintf('(d) PI + FF:  T(0) = %.4f, e_ss = %.4f  (expect 0)\n',     dcgain(T_PIFF), 1-dcgain(T_PIFF))

% Plot the four step responses
t = 0:0.02:8;
figure(3); clf; hold on; grid on; box on
plot(t, ones(size(t)), 'k--', 'DisplayName', 'reference')
plot(t, step(T_P,    t), 'DisplayName', 'P only')
plot(t, step(T_PI,   t), 'DisplayName', 'PI')
plot(t, step(T_PFF,  t), 'DisplayName', 'P + FF')
plot(t, step(T_PIFF, t), 'DisplayName', 'PI + FF')
xlabel('Time (s)'); ylabel('Speed y(t) (m/s)')
title('USV surge: four controller architectures (Exercise 3)')
legend('Location', 'southeast')

%% Exercise 4 -- USV yaw heading: ramp tracking design
%
% Yaw-rate plant:    G_yaw_rate = 0.82 / (0.61 s + 1)
% Heading is the integral of yaw rate, so the heading plant adds 1/s:
%   G_r = G_yaw_rate / s = 0.82 / (s (0.61 s + 1))
% Hand: Kv = 0.82*Kr; spec |e_ss| <= 1 deg for slope = 5 deg/s
%       => Kr >= 5/0.82 = 6.10

K_y       = 0.82;
tau_y     = 0.61;
G_yawrate = tf(K_y, [tau_y 1]);                    % yaw-rate plant
G_r       = tf(K_y, conv([tau_y 1], [1 0]));        % heading plant = G_yawrate / s

Kr_min = 5/K_y;
fprintf('\n--- Exercise 4 ---\n')
fprintf('Min Kr for 1-deg heading error at 5 deg/s ramp: Kr = %.3f\n', Kr_min)

% Simulate ramp response at Kr = Kr_min
Kr   = Kr_min;
T_yh = feedback(Kr * G_r, 1);

t = 0:0.05:25;
r = 5 * t;                     % degrees
y = lsim(T_yh, r, t);
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
