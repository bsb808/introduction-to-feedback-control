%[text] # Week 8 MATLAB Companion: Frequency Response and Bode Plots
%[text] This script follows the chapter examples for frequency response and Bode plot sketching.  It uses the Control System Toolbox and the `sketchbode` utility (in this directory) which overlays the straight-line asymptotic approximation on the exact Bode plot.
%%
%[text] ## Example 10.1: Frequency Response of $G(s) = 1/(s+2)$
%[text] Compute $G(j\omega)$ analytically and compare with the MATLAB Bode plot.
%%
G1 = tf(1, [1 2]);   % G(s) = 1/(s+2)

w = logspace(-1, 2, 200);
[m, p] = bode(G1, w);
m = squeeze(m);
p = squeeze(p);

figure
subplot(2,1,1)
semilogx(w, 20*log10(m), 'b', 'LineWidth', 1.5)
ylabel('Magnitude (dB)')
title('G(s) = 1/(s+2)')
grid on

subplot(2,1,2)
semilogx(w, p, 'b', 'LineWidth', 1.5)
ylabel('Phase (deg)')
xlabel('Frequency (rad/s)')
grid on
%%
%[text] Reference values from the analytical expression: at $\omega = 0$ the magnitude is $20\log(0.5) = -6$~dB and phase is $0^\circ$; at $\omega = 2$ rad/s (the break frequency) the magnitude is $-9$~dB and phase is $-45^\circ$.
[m_check, p_check] = bode(G1, [0.001 2 100]);
fprintf('omega=0.001: mag=%.2f dB, phase=%.1f deg\n', 20*log10(m_check(1)), p_check(1))
fprintf('omega=2:     mag=%.2f dB, phase=%.1f deg\n', 20*log10(m_check(2)), p_check(2))
fprintf('omega=100:   mag=%.2f dB, phase=%.1f deg\n', 20*log10(m_check(3)), p_check(3))
%%
%[text] ## The Four First-Order Building Blocks
%[text] Plot the Bode approximation and exact response for each normalized building block: $s$, $1/s$, $(s/a+1)$, and $1/(s/a+1)$.
%%
a = 5;   % break frequency for the real pole/zero examples

figure
sgtitle('Four first-order building blocks (a = 5 rad/s)', 'Interpreter', 'tex')

% --- Differentiator: G(s) = s
subplot(4,2,1)
sys = tf([1 0], 1);
bode(sys, {0.1, 100});  grid on
title('G(s) = s: magnitude')

subplot(4,2,2)
bode(sys, {0.1, 100});  grid on
title('G(s) = s: phase')

% --- Integrator: G(s) = 1/s
subplot(4,2,3)
sys = tf(1, [1 0]);
bode(sys, {0.1, 100});  grid on
title('G(s) = 1/s')

% --- Real zero: G(s) = s/a + 1
subplot(4,2,5)
sys_z = tf([1/a 1], 1);
sketchbode(sys_z, 1);
title('G(s) = s/a + 1 (zero at a)')

% --- Real pole: G(s) = 1/(s/a + 1)
subplot(4,2,7)
sys_p = tf(1, [1/a 1]);
sketchbode(sys_p, 1);
title('G(s) = 1/(s/a + 1) (pole at a)')
%%
%[text] ## sketchbode: Asymptote vs. Exact
%[text] `sketchbode(sys)` overlays the straight-line asymptote (red) on the exact Bode plot (blue).  The next two examples show how well the asymptote matches for a simple first-order system and where it falls short for a second-order system.
%%
%[text] **First-order pole** — break at $a = 5$ rad/s.  The asymptote matches the exact plot within 3 dB everywhere.
figure
sys_p = tf(1, [1/5 1]);
sketchbode(sys_p);
title('Real pole: 1/(s/5 + 1)  —  asymptote vs. exact')
%%
%[text] **Second-order pole** — natural frequency $\omega_n = 5$ rad/s, damping ratio $\zeta = 0.1$.  The asymptote misses the resonance peak entirely.
wn = 5;  zeta = 0.1;
sys2 = tf(wn^2, [1  2*zeta*wn  wn^2]);

figure
sketchbode(sys2);
title(sprintf('2nd-order pole: \\omega_n=%.0f, \\zeta=%.1f  —  asymptote vs. exact', ...
    wn, zeta), 'Interpreter', 'tex')
%%
%[text] **Effect of damping ratio on the second-order response** — vary $\zeta$ with fixed $\omega_n$.
wn = 5;
zeta_vals = [0.1, 0.3, 0.5, 0.707, 1.0];
labels = {'\zeta=0.1', '\zeta=0.3', '\zeta=0.5', '\zeta=0.707', '\zeta=1.0'};

w = logspace(-1, 2, 300);
figure
subplot(2,1,1)
hold on
for z = zeta_vals
    sys = tf(wn^2, [1  2*z*wn  wn^2]);
    [m, ~] = bode(sys, w);
    semilogx(w, 20*log10(squeeze(m)))
end
hold off
ylabel('Magnitude (dB)')
title(sprintf('2nd-order: fixed \\omega_n = %g, varying \\zeta', wn), 'Interpreter', 'tex')
legend(labels, 'Interpreter', 'tex', 'Location', 'southwest')
grid on

subplot(2,1,2)
hold on
for z = zeta_vals
    sys = tf(wn^2, [1  2*z*wn  wn^2]);
    [~, p] = bode(sys, w);
    semilogx(w, squeeze(p))
end
hold off
ylabel('Phase (deg)')
xlabel('Frequency (rad/s)')
grid on
%%
%[text] ## Worked Example: $G(s) = K(s+3)/[s(s+1)(s+2)]$
%[text] This is the multi-pole example from the chapter.  We use `sketchbode` to check the manual sketch, then compare with the exact Bode plot.
%%
K = 1;
G_ex = tf(K * [1 3], conv([1 0], conv([1 1], [1 2])));

fprintf('Transfer function:\n')
G_ex

fprintf('\nBreak frequencies (poles and zeros of G):\n')
[z, p] = zpkdata(G_ex, 'v');
fprintf('  Zeros: %s\n', mat2str(z, 3))
fprintf('  Poles: %s\n', mat2str(p, 3))
%%
%[text] **Bode form DC gain** — the constant $K_0 = 3K/2$.
K0 = 3*K/2;
fprintf('K0 = 3K/2 = %.4f  =>  %+.2f dB\n', K0, 20*log10(K0))
%%
%[text] **sketchbode overlay** — check the asymptote against the exact plot.
figure
sketchbode(G_ex);
title('G(s) = K(s+3)/[s(s+1)(s+2)],  K=1', 'Interpreter', 'tex')
%%
%[text] **Verify key points on the magnitude asymptote** — the asymptote at $\omega = 0.1$ should be approximately 23.5 dB.
w_check = [0.1, 1, 2, 3, 10];
[m_ex, p_ex] = bode(G_ex, w_check);
m_ex = squeeze(m_ex);
p_ex = squeeze(p_ex);
fprintf('\nomega   |  mag (dB)  |  phase (deg)\n')
fprintf('--------|------------|-------------\n')
for k = 1:length(w_check)
    fprintf(' %5.1f  |   %6.2f   |   %7.2f\n', ...
        w_check(k), 20*log10(m_ex(k)), p_ex(k))
end
%%
%[text] ## USV Surge Model
%[text] The first-order surge transfer function identified in the lab relates throttle effort to forward speed.  Its Bode plot shows the single pole (bandwidth) of the surge dynamics.
%%
%[text] Typical identified parameters: DC gain $K_{dc} = 2$ m/s per unit effort, time constant $\tau = 10$ s (pole at $a = 1/\tau = 0.1$ rad/s).
K_surge = 2;
tau_surge = 10;
a_surge = 1/tau_surge;
G_surge = tf(K_surge * a_surge, [1  a_surge]);   % K*a/(s+a)

fprintf('Surge TF: DC gain = %.2f (m/s)/effort, break freq = %.3f rad/s\n', ...
    K_surge, a_surge)

figure
sketchbode(G_surge);
title(sprintf('USV surge: G(s) = %.1f \\cdot %.2f/(s+%.2f)', ...
    K_surge, a_surge, a_surge), 'Interpreter', 'tex')

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
