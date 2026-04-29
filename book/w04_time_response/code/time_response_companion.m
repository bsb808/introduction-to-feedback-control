%[text] # Week 4 MATLAB Companion: Time Response
%[text] This script follows the chapter examples for first- and second-order time response.  All MATLAB commands use the Control System Toolbox.
%%
%[text] ## First-Order Systems
%[text] The canonical first-order transfer function is $G\_1(s) = K\_{dc}\\,a/(s+a)$.  We build it with `tf()` and plot the unit step response.
%%
%[text] **Example: varying time constant** — three first-order systems with the same DC gain but different poles
a_vals = [1, 2, 5];          % pole locations: a = 1/tau
Kdc = 2;
figure
hold on
for a = a_vals
    G = tf(Kdc * a, [1, a]);
    step(G)
end
hold off
legend('\tau = 1', '\tau = 0.5', '\tau = 0.2', 'Location', 'southeast')
title('First-order step responses: same K_{dc}, different \tau')
xlabel('Time (s)');  ylabel('Amplitude')
grid on
%%
%[text] **Annotating the time constant** — the response reaches 63% of its final value at $t = \\tau$
a = 2;  tau = 1/a;  Kdc = 1.5;
G1 = tf(Kdc * a, [1, a]);
t = 0 : 0.01 : 4*tau;
c = Kdc * (1 - exp(-a*t));

figure
plot(t, c, 'b')
hold on
plot(tau, Kdc*(1-exp(-1)), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r')
yline(Kdc, 'k--')
yline(0.63*Kdc, 'r--')
xline(tau, 'r--')
xline(4*tau, 'g--')
text(tau+0.02, 0.1, '\tau', 'Color', 'r', 'FontSize', 12)
text(4*tau+0.02, 0.1, '4\tau = T_s', 'Color', 'g', 'FontSize', 12)
text(0.05, Kdc+0.05, 'K_{dc}', 'FontSize', 12)
hold off
title('First-order step response: annotated metrics')
xlabel('Time (s)');  ylabel('c(t)')
grid on
%%
%[text] **Rise time and settling time** — compute and verify with `stepinfo()`
info = stepinfo(G1)
Tr_formula  = 2.2 / a
Ts_formula  = 4.0 / a
%%
%[text] ## Second-Order Systems: Four Damping Cases
%[text] The canonical second-order TF is $G\_2(s) = K\_{dc}\\,\\omega\_{n}^{2}/(s^{2}+2\\zeta\\omega\_{n}s+\\omega\_{n}^{2})$.  Varying $\\zeta$ produces qualitatively different responses.
%%
wn = 3;   Kdc = 1;
zeta_vals = [0, 0.3, 0.5, 0.707, 1.0, 1.5];
labels = {'\zeta=0 (undamped)', '\zeta=0.3', '\zeta=0.5', ...
          '\zeta=0.707 (crit. equiv.)', '\zeta=1 (critically damped)', ...
          '\zeta=1.5 (overdamped)'};

figure
hold on
for k = 1:length(zeta_vals)
    z = zeta_vals(k);
    G = tf(Kdc * wn^2, [1, 2*z*wn, wn^2]);
    step(G)
end
hold off
legend(labels, 'Location', 'southeast', 'Interpreter', 'tex')
title('Second-order step responses: varying damping ratio')
xlabel('Time (s)');  ylabel('c(t)')
grid on
%%
%[text] ## Pole-Zero Map and Step Response Together
%[text] A side-by-side view reinforces the connection between pole location and response character.
%%
wn = 5;  Kdc = 1;
zeta_vals = [0.1, 0.3, 0.5, 0.707, 1.0, 1.5];

figure
for k = 1:length(zeta_vals)
    z = zeta_vals(k);
    G = tf(Kdc * wn^2, [1, 2*z*wn, wn^2]);
    subplot(length(zeta_vals), 2, 2*k-1)
    pzplot(G);  grid on
    title(sprintf('\\zeta = %.3g', z), 'Interpreter', 'tex')
    subplot(length(zeta_vals), 2, 2*k)
    step(G);  grid on
    title('')
end
%%
%[text] ## System Parameters from the Transfer Function
%[text] Given a transfer function, use `damp()` to extract $\\omega\_{n}$ and $\\zeta$ for each pole pair.
%%
G_ex = tf(100, [1, 15, 100]);   % wn = 10, zeta = 0.75
[wn_vals, zeta_vals, poles] = damp(G_ex)
%%
%[text] **Identifying parameters by inspection** — match coefficients to the standard form $s^{2}+2\\zeta\\omega\_{n}s+\\omega\_{n}^{2}$
num = G_ex.Numerator{1};
den = G_ex.Denominator{1};
wn_id   = sqrt(den(3))
zeta_id = den(2) / (2 * wn_id)
Kdc_id  = num(end) / den(end)
%%
%[text] ## Performance Metrics: Formulas vs. `stepinfo()`
%[text] For the canonical underdamped system (no zeros, no additional poles) the formulas of the chapter give exact results.  `stepinfo()` computes the same quantities numerically from the step response.
%%
wn = 10;  zeta = 0.4;
G = tf(wn^2, [1, 2*zeta*wn, wn^2]);

wd  = wn * sqrt(1 - zeta^2);
sig = zeta * wn;

Tp_formula  = pi / wd
OS_formula  = exp(-pi*zeta/sqrt(1-zeta^2)) * 100
Ts_formula  = 4 / sig
% Rise time: Nise polynomial (max error < 0.5% for 0 < zeta < 0.9)
wnTr = 1.76*zeta^3 - 0.417*zeta^2 + 1.039*zeta + 1;
Tr_formula  = wnTr / wn
%%
info = stepinfo(G)
%%
%[text] ## Effect of Natural Frequency: Time Scaling
%[text] Increasing $\\omega\_{n}$ with fixed $\\zeta$ compresses the time axis without changing the shape --- overshoot and number of oscillations stay the same.
%%
zeta = 0.4;
wn_vals = [2, 5, 10];
figure
hold on
for wn = wn_vals
    G = tf(wn^2, [1, 2*zeta*wn, wn^2]);
    step(G)
end
hold off
legend('\omega_n = 2', '\omega_n = 5', '\omega_n = 10', ...
       'Location', 'southeast', 'Interpreter', 'tex')
title(sprintf('Time scaling: fixed \\zeta = %.1f, varying \\omega_n', zeta), ...
      'Interpreter', 'tex')
xlabel('Time (s)');  ylabel('c(t)')
grid on
%%
%[text] ## Effect of Damping Ratio: Shape Change
%[text] Increasing $\\zeta$ with fixed $\\omega\_{n}$ reduces overshoot and rises time changes.  The natural frequency sets the time scale; $\\zeta$ sets the shape.
%%
wn = 5;
zeta_vals = [0.1, 0.3, 0.5, 0.707];
figure
hold on
for zeta = zeta_vals
    G = tf(wn^2, [1, 2*zeta*wn, wn^2]);
    step(G)
end
hold off
legend('\zeta=0.1', '\zeta=0.3', '\zeta=0.5', '\zeta=0.707', ...
       'Location', 'southeast', 'Interpreter', 'tex')
title(sprintf('Shape change: fixed \\omega_n = %g, varying \\zeta', wn), ...
      'Interpreter', 'tex')
xlabel('Time (s)');  ylabel('c(t)')
grid on
%%
%[text] ## Higher-Order Systems: Numerical Metrics
%[text] For higher-order models or systems with zeros, `stepinfo()` and `damp()` compute the metrics numerically without requiring the analytical formulas.
%%
% Three-pole system from Nise Example 4.8
G_hi = tf(24.542, [1, 4, 24.542]);          % pure second-order baseline
G_hi2 = tf(245.42, conv([1 10], [1 4 24.542]));  % third pole at -10

figure
step(G_hi, G_hi2)
legend('2nd-order baseline', 'With extra pole at -10', 'Location', 'southeast')
title('Effect of an additional pole on step response')
grid on

info1 = stepinfo(G_hi)
info2 = stepinfo(G_hi2)

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
