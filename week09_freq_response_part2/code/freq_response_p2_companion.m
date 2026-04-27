%[text] # Week 9 MATLAB Companion: Stability Margins and Gain Design
%[text] This script follows the chapter examples for reading gain and phase margins from Bode plots, relating phase margin to damping ratio, and designing a proportional gain to meet a percent overshoot specification.
%%
%[text] ## Stability Margins with `margin()`
%[text] The `margin()` function computes and displays gain margin $G\_M$, phase margin $\Phi\_M$, and both crossover frequencies directly from a transfer function.
%%
%[text] **Example: $G(s) = 200/[(s+2)(s+4)(s+5)]$**
G = tf(200, conv([1 2], conv([1 4], [1 5])));

[Gm, Pm, Wcg, Wcp] = margin(G);
fprintf('Gain margin:           %.2f dB  (at %.2f rad/s)\n', 20*log10(Gm), Wcg)
fprintf('Phase margin:          %.2f deg (at %.2f rad/s)\n', Pm, Wcp)
%%
%[text] **Annotated Bode plot** — `margin(G)` draws the Bode diagram with both margins marked.
figure
margin(G)
title('G(s) = 200/[(s+2)(s+4)(s+5)]  —  stability margins', 'Interpreter', 'tex')
%%
%[text] **Reading margins by hand** — use `bode()` to evaluate at the crossover frequencies and confirm the values above.
[m_pc, p_pc] = bode(G, Wcg);   % at phase crossover
[m_gc, p_gc] = bode(G, Wcp);   % at gain crossover

fprintf('\nAt phase crossover (omega = %.2f rad/s):\n', Wcg)
fprintf('  magnitude = %.2f dB  (gain margin = -%.2f dB = +%.2f dB)\n', ...
    20*log10(m_pc), 20*log10(m_pc), -20*log10(m_pc))
fprintf('  phase     = %.2f deg\n', p_pc)

fprintf('\nAt gain crossover (omega = %.2f rad/s):\n', Wcp)
fprintf('  magnitude = %.4f (= 0 dB check)\n', m_gc)
fprintf('  phase     = %.2f deg\n', p_gc)
fprintf('  phase margin = 180 + %.2f = %.2f deg\n', p_gc, 180 + p_gc)
%%
%[text] ## Phase Margin vs. Damping Ratio
%[text] Equation (10.73) from the chapter gives the exact relationship between phase margin and damping ratio for the standard second-order open-loop transfer function.  We plot it here and use it in both directions.
%%
zeta_vec = linspace(0.01, 1.0, 200);
Pm_vec = atan2d( 2*zeta_vec, sqrt(-2*zeta_vec.^2 + sqrt(1 + 4*zeta_vec.^4)) );

figure
plot(zeta_vec, Pm_vec, 'b', 'LineWidth', 1.5)
xlabel('Damping ratio \zeta')
ylabel('Phase margin \Phi_M (deg)')
title('Phase margin vs. damping ratio — Eq. (10.73)', 'Interpreter', 'tex')
grid on
%%
%[text] **Inverse use: from \%OS to $\zeta$ to $\Phi\_M$** — given a percent overshoot specification, compute the required phase margin.
pos_spec = [5, 9.5, 20, 30];   % percent overshoot values

fprintf('\n%%-OS  |  zeta  |  Phi_M (deg)\n')
fprintf('------|--------|-------------\n')
for pos = pos_spec
    zeta = -log(pos/100) / sqrt(pi^2 + log(pos/100)^2);
    Pm_req = atan2d(2*zeta, sqrt(-2*zeta^2 + sqrt(1 + 4*zeta^4)));
    fprintf('  %4.1f |  %.3f |  %.1f\n', pos, zeta, Pm_req)
end
%%
%[text] ## Closed-Loop Bandwidth
%[text] Equation (10.54) gives the closed-loop bandwidth $\omega\_{BW}$ in terms of $\omega\_n$ and $\zeta$.  These plots show how bandwidth relates to damping ratio and to the transient time metrics.
%%
zeta_vec2 = linspace(0.01, 0.95, 200);
bw_factor = sqrt( (1 - 2*zeta_vec2.^2) + sqrt(4*zeta_vec2.^4 - 4*zeta_vec2.^2 + 2) );

figure
subplot(2,1,1)
plot(zeta_vec2, bw_factor, 'b', 'LineWidth', 1.5)
xlabel('Damping ratio \zeta')
ylabel('\omega_{BW} / \omega_n')
title('Normalized bandwidth vs. damping ratio', 'Interpreter', 'tex')
grid on

%[text] Settling-time form: $\omega\_{BW} = (4 / T\_s \zeta) \cdot \sqrt{(1-2\zeta^2)+\sqrt{4\zeta^4-4\zeta^2+2}}$
subplot(2,1,2)
plot(zeta_vec2, bw_factor ./ zeta_vec2, 'b', 'LineWidth', 1.5)
xlabel('Damping ratio \zeta')
ylabel('\omega_{BW} \cdot T_s / 4')
title('Bandwidth \times settling time (normalized)', 'Interpreter', 'tex')
grid on
%%
%[text] **Example: required bandwidth** — find $\omega\_{BW}$ for 10\% overshoot and a 2-second settling time.
pos = 10;
zeta = -log(pos/100) / sqrt(pi^2 + log(pos/100)^2);
Ts  = 2;

bw_factor_val = sqrt((1 - 2*zeta^2) + sqrt(4*zeta^4 - 4*zeta^2 + 2));
wBW = (4 / (Ts * zeta)) * bw_factor_val;

fprintf('\n%% OS = %.0f  =>  zeta = %.3f\n', pos, zeta)
fprintf('Ts = %.1f s  =>  wBW = %.2f rad/s\n', Ts, wBW)
%%
%[text] ## Gain Adjustment Design: Four-Step Procedure
%[text] We implement the design procedure from the chapter step by step.  The system is the position control example: $G(s) = 100K/[s(s+36)(s+100)]$.  The specification is 9.5\% overshoot.
%%
%[text] **Step 1 — Initial Bode plot.**  Choose $K = 3.6$ as a convenient starting gain (places the initial 0 dB crossing near $\omega = 0.1$ rad/s).
K_start = 3.6;
G_plant = tf(100, conv([1 0], conv([1 36], [1 100])));
G_init  = K_start * G_plant;

figure
margin(G_init)
title(sprintf('Initial Bode: K = %.1f', K_start), 'Interpreter', 'tex')
%%
%[text] **Step 2 — Required phase margin.**  Convert the \%OS specification to $\zeta$, then to $\Phi\_M$ via Eq.~(10.73).
pos_spec_val = 9.5;
zeta_req = -log(pos_spec_val/100) / sqrt(pi^2 + log(pos_spec_val/100)^2);
Pm_req   = atan2d(2*zeta_req, sqrt(-2*zeta_req^2 + sqrt(1 + 4*zeta_req^4)));

fprintf('\n%% OS = %.1f  =>  zeta = %.3f  =>  required Phi_M = %.1f deg\n', ...
    pos_spec_val, zeta_req, Pm_req)
%%
%[text] **Step 3 — Find the target frequency $\omega^*$.**  We need the frequency where the open-loop phase equals $\Phi\_M - 180^\circ$.  Search the phase curve numerically.
phase_target = Pm_req - 180;   % degrees

w_vec = logspace(-1, 3, 5000);
[~, p_vec] = bode(G_init, w_vec);
p_vec = squeeze(p_vec);

% find zero crossing of (phase - phase_target)
idx = find(diff(sign(p_vec - phase_target)) ~= 0, 1);
w_star = interp1(p_vec(idx:idx+1), w_vec(idx:idx+1), phase_target);

fprintf('Phase target: %.1f deg\n', phase_target)
fprintf('Target frequency omega* = %.2f rad/s\n', w_star)
%%
%[text] **Step 4 — Adjust $K$.**  Read the current magnitude at $\omega^*$ and adjust $K$ to bring it to 0 dB.
[m_star, ~] = bode(G_init, w_star);
m_star_dB   = 20*log10(m_star);

dK_dB = -m_star_dB;   % amount to raise the magnitude
K_adj = K_start * 10^(dK_dB/20);

fprintf('\nMagnitude at omega* (K = %.1f): %.2f dB\n', K_start, m_star_dB)
fprintf('Required adjustment: +%.2f dB\n', dK_dB)
fprintf('Adjusted K = %.1f * 10^(%.2f/20) = %.1f\n', K_start, dK_dB, K_adj)
%%
%[text] **Result: verify margins and step response.**
G_designed = K_adj * G_plant;

[Gm_d, Pm_d, ~, Wcp_d] = margin(G_designed);
fprintf('\nDesigned system:\n')
fprintf('  K = %.1f\n', K_adj)
fprintf('  Phase margin = %.1f deg  (target: %.1f deg)\n', Pm_d, Pm_req)
fprintf('  Gain crossover = %.2f rad/s\n', Wcp_d)

figure
margin(G_designed)
title(sprintf('Designed system: K = %.1f,  \\Phi_M = %.1f°', K_adj, Pm_d), ...
    'Interpreter', 'tex')
%%
%[text] **Closed-loop step response** — confirm the percent overshoot.
T_cl = feedback(G_designed, 1);

figure
step(T_cl)
info = stepinfo(T_cl);
title(sprintf('Step response: %%OS = %.1f%%,  T_p = %.3f s', ...
    info.Overshoot, info.PeakTime), 'Interpreter', 'tex')
xlabel('Time (s)');  ylabel('c(t)')
grid on

fprintf('\nStep response metrics:\n')
fprintf('  %% Overshoot  = %.2f%%  (spec: %.1f%%)\n', info.Overshoot, pos_spec_val)
fprintf('  Peak time    = %.3f s\n', info.PeakTime)
fprintf('  Settling time = %.3f s\n', info.SettlingTime)
%%
%[text] ## USV Surge Model: Frequency-Domain Analysis
%[text] The first-order surge model from the lab has a first-order open-loop transfer function.  We close the loop with a proportional gain and analyze the stability margins.
%%
%[text] Typical surge model parameters: DC gain $K\_{dc} = 2$ m/s per unit effort, time constant $\tau = 10$ s.  For a closed-loop speed controller, the open-loop transfer function is $G\_{surge}(s) = K \cdot K\_{dc} \cdot a / (s+a)$.
Kdc_surge = 2;
tau_surge  = 10;
a_surge    = 1/tau_surge;

%[text] Plant: $G\_{plant}(s) = K\_{dc} \cdot a/(s+a) = 0.2/(s+0.1)$
G_surge_plant = tf(Kdc_surge * a_surge, [1  a_surge]);

%[text] Loop with proportional gain $K\_p$: $G\_{ol}(s) = K\_p \cdot G\_{plant}(s)$.  We sweep $K\_p$ and compute the phase margin for each.
Kp_vals = [1.0, 2.0, 5.0, 10.0];

fprintf('\nSurge speed controller: G_plant = %.2f/(s+%.2f)\n', Kdc_surge*a_surge, a_surge)
fprintf('\nKp    | Phi_M (deg) | Wcp (rad/s)\n')
fprintf('------|-------------|------------\n')
for Kp = Kp_vals
    [~, Pm_s, ~, Wcp_s] = margin(Kp * G_surge_plant);
    fprintf(' %.2f |    %5.1f    |    %.3f\n', Kp, Pm_s, Wcp_s)
end
%%
%[text] **Step responses for several $K\_p$ values** — a first-order plant in unity feedback is always stable; increasing $K\_p$ speeds the response but cannot cause oscillation.
t_vec = linspace(0, 60, 500);
figure
hold on
for Kp = Kp_vals
    T_surge = feedback(Kp * G_surge_plant, 1);
    y = step(T_surge, t_vec);
    plot(t_vec, y)
end
hold off
legend('K\_p = 1.0', 'K\_p = 2.0', 'K\_p = 5.0', 'K\_p = 10.0', ...
    'Interpreter', 'tex', 'Location', 'southeast')
title('Closed-loop surge speed step responses: varying K\_p', 'Interpreter', 'tex')
xlabel('Time (s)');  ylabel('Speed (m/s)')
grid on
%%
%[text] **Note:** the phase margin of a first-order plant in unity feedback is always greater than $90^\circ$ for any $K\_p > 0$, so there is no overshoot in the step response.  The gain adjustment procedure becomes more meaningful when the plant has additional poles (like the position control example above).

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
