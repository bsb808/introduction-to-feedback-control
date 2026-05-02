%[text] # Simulating Steady-State Error: Step, Ramp, and Parabola Inputs
%[text] This supplemental note shows two ways to simulate the closed-loop response of a system to the three standard test inputs used in steady-state error analysis: step, ramp, and parabola.  MATLAB provides a convenient `step()` command for the unit step.  There is no built-in `ramp()` or `parabola()`, so we need a workaround.  Two general approaches are illustrated for each input.
%[text] **Method 1 — Cascade an integrator with the closed-loop transfer function.**  A unit step driven through $1/s$ becomes a ramp ($r(t)=t$); through $1/s^2$ it becomes a parabola ($r(t)=t^2/2$).  We absorb these integrators into the transfer function passed to `step()`.
%[text] **Method 2 — Build the input signal as a time vector and call** **`lsim()`****.**  This generalizes to any input (sinusoids, disturbances, recorded data) so it is worth seeing alongside the `step()` trick.
%[text] We use a Type 1 plant (one open-loop integrator) so that the three inputs produce three qualitatively different steady-state behaviors: zero step error, finite ramp error, and unbounded parabola error.
%%
%[text] ## Example System (Type 1)
%[text] A simple Type 1 plant: $G\_\\mathrm{ol}(s) = 10/(s(s+4))$.  The free $s$ in the denominator is the open-loop integrator that makes this Type 1.  The closed-loop transfer function $G\_\\mathrm{cl}(s)$ is formed with `feedback()` (unity feedback).
clear;
Gol = tf(10,[1 4 0]);
Gcl = feedback(Gol, 1);
%[text] The velocity error constant is $K\_v = \\lim\_{s\\to 0} sG\_\\mathrm{ol}(s) = 10/4 = 2.5$.  Using `minreal` to cancel the $s/s$ pole-zero pair lets `dcgain` evaluate the limit cleanly.
s  = tf('s');
Kv = dcgain(minreal(s*Gol));
e_ss_ramp_expected = 1/Kv;
fprintf('Kv = %.3f, expected ramp e_ss = %.3f\n', Kv, e_ss_ramp_expected)
%%
%[text] ## Common Time Vector
%[text] All three simulations share the same time grid.  The closed-loop dynamics settle within a few seconds, so a ten-second window comfortably shows both the transient and the steady-state behavior.
t = (0:0.01:10)';
%%
%[text] ## Step Input
%[text] The convenient case.  `step(Gcl,t)` simulates the unit step response directly.
%[text] **Method 1 —** **`step()`** **directly.**
y_step_A = step(Gcl, t);
%[text] **Method 2 —** **`lsim()`** **with** $r(t) = 1$**.**
r_step = ones(size(t));
y_step_B = lsim(Gcl, r_step, t);
%[text] Plot the input and both outputs.  The two outputs overlay exactly.
figure
plot(t, r_step,   'k--', 'DisplayName','input  r(t) = 1')
hold on
plot(t, y_step_A, 'b-',  'LineWidth', 1.5, 'DisplayName','step(Gcl, t)')
plot(t, y_step_B, 'r:',  'LineWidth', 1.5, 'DisplayName','lsim(Gcl, ones(size(t)), t)')
hold off
grid on
xlabel('Time (s)');  ylabel('Response')
title('Unit Step Response — Two Methods')
legend('Location','southeast')
%[text] For this Type 1 system, $K\_x = \\infty$ and the step error tends to zero.
e_step_meas = r_step(end) - y_step_B(end);
fprintf('Measured step e_ss = %.4f (expected 0)\n', e_step_meas)
%%
%[text] ## Ramp Input
%[text] No built-in `ramp()` command.  A unit ramp is $r(t) = t$, with Laplace transform $1/s^2$.
%[text] **Method 1 — Cascade an integrator** $1/s$ **in front of** $G\_\\mathrm{cl}(s)$**, then call** **`step()`****.**  Driving $G\_\\mathrm{cl}(s) \\cdot 1/s$ with a unit step is the same as driving $G\_\\mathrm{cl}(s)$ with a ramp, since $1 \\cdot \\frac{1}{s} \\cdot \\frac{1}{s} = \\frac{1}{s^2}$, the Laplace transform of $r(t)=t$.
Gcl_ramp = Gcl * tf(1, [1, 0]);          % Gcl(s) / s
y_ramp_A = step(Gcl_ramp, t);
%[text] **Method 2 — Build** $r(t)=t$ **explicitly and call** **`lsim()`****.**
r_ramp   = t;
y_ramp_B = lsim(Gcl, r_ramp, t);
%[text] Both methods produce the same response.  The output tracks the ramp with a constant offset.
figure
plot(t, r_ramp,   'k--', 'DisplayName','input  r(t) = t')
hold on
plot(t, y_ramp_A, 'b-',  'LineWidth', 1.5, 'DisplayName','step(Gcl/s, t)')
plot(t, y_ramp_B, 'r:',  'LineWidth', 1.5, 'DisplayName','lsim(Gcl, t, t)')
hold off
grid on
xlabel('Time (s)');  ylabel('Response')
title('Unit Ramp Response — Two Methods')
legend('Location','northwest')
%[text] The steady-state offset between input and output is $e\_{ss} = 1/K\_v$.
e_ss_ramp_meas = r_ramp(end) - y_ramp_B(end);
fprintf('Measured ramp e_ss = %.4f (expected %.4f)\n', e_ss_ramp_meas, e_ss_ramp_expected)
%%
%[text] ## Parabola Input
%[text] No built-in command.  A unit parabola is $r(t) = \\frac{1}{2}t^2$, with Laplace transform $1/s^3$.
%[text] **Method 1 — Cascade** $1/s^2$ **in front of** $G\_\\mathrm{cl}(s)$**, then call** **`step()`****.**  The full chain is $1 \\cdot \\frac{1}{s} \\cdot \\frac{1}{s^2} = \\frac{1}{s^3}$, which is the Laplace transform of $\\frac{1}{2}t^2$.
Gcl_para = Gcl * tf(1, [1, 0, 0]);       % Gcl(s) / s^2
y_para_A = step(Gcl_para, t);
%[text] **Method 2 — Build** $r(t)=\\frac{1}{2}t^2$ **explicitly and call** **`lsim()`****.**
r_para   = 0.5*t.^2;
y_para_B = lsim(Gcl, r_para, t);
%[text] For a Type 1 plant the parabola error grows without bound: $K\_a = 0$, so $e\_{ss} \\to \\infty$.  The output falls progressively further behind the parabola.
figure
plot(t, r_para,   'k--', 'DisplayName','input  r(t) = t^2 / 2')
hold on
plot(t, y_para_A, 'b-',  'LineWidth', 1.5, 'DisplayName','step(Gcl/s^2, t)')
plot(t, y_para_B, 'r:',  'LineWidth', 1.5, 'DisplayName','lsim(Gcl, t^2/2, t)')
hold off
grid on
xlabel('Time (s)');  ylabel('Response')
title('Unit Parabola Response — Two Methods')
legend('Location','northwest')
%[text] The error sampled at the end of the simulation window is already large and still growing.
e_para_meas = r_para(end) - y_para_B(end);
fprintf('Parabola error at t=%.1fs: %.3f (grows without bound for Type 1)\n', t(end), e_para_meas)
%%
%[text] ## Summary
%[text] For each test input there are (at least) two convenient ways to simulate the closed-loop response:
%[text] - **Step:** `step(Gcl, t)`  or  `lsim(Gcl, ones(size(t)), t)`
%[text] - **Ramp:** `step(Gcl/s, t)`  or  `lsim(Gcl, t, t)`
%[text] - **Parabola:** `step(Gcl/s^2, t)`  or  `lsim(Gcl, 0.5*t.^2, t)` \
%[text] The `step()` trick (Method 1) is compact and emphasizes the underlying frequency-domain structure: cascading an integrator with the closed-loop TF turns the test input into the next-higher-order signal.  `lsim()` (Method 2) is more general — it accepts any time-series input — and is the right tool when you want to drive the system with a sinusoid, a recorded reference, or a disturbance signal.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
