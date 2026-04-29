
%% The effects of input filtering on feedback control
% This script demonstrates both linear (first-order low-pass filter) and
% non-linear (rate limiter) command filtering.

%% Section 1: Time response of input filters
% Compare LPF and rate limiter on a unit step.
% tau = 1 s, R = 1/tau = 1 unit/s so the rate limit equals the initial
% slope of the LPF step response.

tau = 1;        % LPF time constant (s)
R   = 1/tau;    % rate limit (units/s)

dt = 0.01;
t = (0 : dt : 6)';

% LPF step response via transfer function
sys_lpf = tf(1, [tau 1]);
y_lpf   = step(sys_lpf, t);

% Rate-limited step response: ramps at rate R until it reaches 1
y_rl = min(R * t, 1);

figure(1); clf;
subplot(311)
plot(t, y_lpf, t, y_rl, '--');
legend('LPF (\tau = 1 s)', 'Rate limiter (R = 1 unit/s)', ...
    'Interpreter', 'latex', 'Location', 'southeast');
xlabel('Time (s)');
ylabel('Output');
title('Unit step response: LPF vs. rate limiter', 'Interpreter', 'latex');
grid on;

%% Amplitude dependency
% Increase step to A = 10 with the same R = 1 unit/s.
% The LPF scales linearly (same shape, larger amplitude); the rate limiter
% takes 10x as long to reach the setpoint — equivalence breaks down.

A = 10;
t2 = (0 : dt : 60)';

y_lpf2 = A * step(sys_lpf, t2);
y_rl2  = min(R * t2, A);

subplot(312)
plot(t2, y_lpf2, t2, y_rl2, '--');
legend('LPF (\tau = 1 s)', 'Rate limiter (R = 1 unit/s)', ...
    'Interpreter', 'latex', 'Location', 'southeast');
xlabel('Time (s)');
ylabel('Output');
title('Step A = 10: Equivalence breaks down', 'Interpreter', 'latex');
grid on;


%% Rate limit and time constant equivalency
% Fix: set R = A/tau so the ramp time again equals tau.
%    tau = A/R <=>  R = A/tau
% Modify the first-order filter to limit initial slope to R
tau2 = A/R;
sys_lpf2 = tf(1, [tau2 1]);
y_lpf3 = A * step(sys_lpf2, t2);

subplot(313)
plot(t2, y_lpf3, t2, y_rl2, '--');
legend('LPF (\tau = 1 s)', 'Rate limiter (R = A/\tau = 10 unit/s)', ...
    'Interpreter', 'latex', 'Location', 'southeast');
xlabel('Time (s)');
ylabel('Output');
title('Step A = 10: Equivalence restored ($\tau = A/R$)', 'Interpreter', 'latex');
grid on;


%% Effect of input filtering on closed-loop performance.
% Consider this open-loop model, similar to yaw model for mobile robot.
Gol = tf(1,[1 1 0]);
% Proportional only feedback 
% Design goal of achieve the fastest respesponse with \zeta \geq 0.707
zeta = 0.707;
% Option 1 - no input filter
% Closed form solution for command->output
Kp1 = (1/(2*zeta))^2;  
Gcl1 = (Kp1*Gol)/(1+Kp1*Gol);
tt = (0:dt:14)';
yy1 = step(Gcl1,tt);
% We can also look at the "control sensitivity function" which provides the
% command->plant-input (U) response to see how hard the system is pushing
% the plant.
Gu1 = Kp1/(1+Kp1*Gol);
uu1 = step(Gu1,tt);

figure(4);
clf();
subplot(211)
plot(tt,yy1, "DisplayName","No Input Filter")
grid on
hold on;
ylabel("Output (units)")
subplot(212)
plot(tt,uu1, "DisplayName","No Input Filter")
hold on;
grid on
xlabel('Time (s)')
ylabel("Control effort (units)")
% Option 2 - low-pass input filter.  Now we have to parameters to change
Kp2 = Kp1*1.1;
tau = 0.5;

Glp = tf(1,[tau 1]);
Gcl2 = Glp*feedback(Kp2 * Gol, 1);
yy2 = step(Gcl2, tt);
Gu2 = Glp* (Kp2/(1+Kp2*Gol));
uu2 = step(Gu2, tt);

subplot(211)
plot(tt, yy2, "DisplayName","Low-Pass Input Filter")
subplot(212)
plot(tt, uu2, "DisplayName","Low-Pass Input Filter")

% Option 3 - rate limit filter
% This takes a little different approach for a non-linear fitler.
% First generate the output of the rate limiter
R = 1/tau;
y_rl = min(R * tt, 1);
% Then generate the response of the downstream system
yy3 = lsim(feedback(Kp2 * Gol, 1), y_rl, tt);
uu3 = lsim(Kp2/(1+Kp2*Gol), y_rl, tt);
subplot(211)
plot(tt, yy3,"DisplayName", "Rate Limit Input Filter")
legend("Location","southeast")
subplot(212)
plot(tt,uu3,"DisplayName", "Rate Limit Input Filter")


% Key takeaways on input filtering:
%
% 1. Output performance is similar across all three options.  With
%    appropriate gain tuning, whether you use no filter, an LPF, or a rate
%    limiter, the closed-loop step response looks roughly the same.  Input
%    filtering trades a small amount of speed for smoother behavior.
%
% 2. The real benefit shows up in the control effort.  Without a filter,
%    the controller sees a full step error at t=0 and immediately demands
%    maximum effort — an instantaneous jump in the plant input.  This is
%    physically unrealizable (you can't deflect a rudder or open a throttle
%    instantly) and puts unnecessary stress on actuators.
%
% 3. The LPF produces a truly smooth command; the rate limiter has a
%    corner.  The LPF output is exponential (infinitely smooth), so the
%    control effort transitions continuously.  The rate-limited command
%    switches abruptly from ramp to constant at t = A/R, which appears as
%    a kink in the control effort — less severe than no filter, but still a
%    non-smooth transition.
%
% 4. The rate limiter is nonlinear; its equivalent time constant depends on
%    amplitude.  Large setpoint changes take proportionally longer to
%    settle, which is not the case for the LPF.  The equivalence R = A/tau
%    must be re-evaluated whenever the command amplitude changes.
%
% 5. Preview for frequency response: the LPF has a well-defined cutoff
%    frequency (w = 1/tau rad/s) that directly characterizes which command
%    frequencies pass through to the plant.  This makes the LPF easy to
%    reason about in the frequency domain — we will return to this once we
%    cover frequency response and Bode plots.