%[text] # Rate Limiter vs. Low-Pass Filter
%[text] 
%[text] This script compares two ways to smooth a step command:
%[text] 
%[text] 1. **Linear first-order low-pass filter** with time constant $\\tau$: \
%[text] $\\frac{Y(s)}{U(s)} = \\frac{1}{\\tau s + 1}$
%[text] 
%[text] 1. **Rate limiter** that constrains $|\\dot{y}| \\le R$ \
%[text] (analogous to the ArduPilot `ATC_ACCEL_MAX` parameter).
%%
%[text] ## Equivalence Condition
%[text] 
%[text] For a step input of amplitude $A$, the LPF output is
%[text] $y\_{\\mathrm{LPF}}(t) = A \\left(1 - e^{-t/\\tau}\\right)$
%[text] with initial slope $\\dot{y}(0^+) = A/\\tau$.
%[text] 
%[text] The rate limiter ramps at constant rate $R$ until it reaches $A$ at
%[text] time $t = A/R$, so the ramp time equals $\\tau$ when
%[text] $R = \\frac{A}{\\tau} \\quad\\Longleftrightarrow\\quad \\tau = \\frac{A}{R}$
%[text] 
%[text] **Key nonlinearity:** the LPF time constant $\\tau$ is independent of $A$
%[text] (linear system).  The rate limiter is nonlinear — its equivalent time constant
%[text] $A/R$ grows with step size, so large steps settle more slowly than small ones.
%%
%[text] ## Parameters
%%
dt   = 0.01;          % time step (s)
T    = 1;            % simulation duration (s)
t    = (0:dt:T)';
A=1;  % Amplitude
tau  = 2.0;           % LPF time constant (s)
R    = A / tau;       % equivalent rate limit  [same units as A per second]

fprintf('Time constant tau = %.2f s\n', tau) %[output:3d615c42]
fprintf('Step amplitude  A = %.2f\n',   A) %[output:9ed71da0]
fprintf('Rate limit      R = A/tau = %.4f per second\n', R) %[output:798e5e05]
%%
%[text] ## Simulate Both Responses
%%
% Step input
u = A * (t >= t_step); %[output:66de6dd2]

% Low-pass filter response (analytical)
t_rel = max(t - t_step, 0);
figure()
clf()
plot(t, t_rel)
y_lpf = A * (1 - exp(-t_rel / tau));

% Rate limiter response (analytical for step: ramp then hold)
y_rl = min(R * t_rel, A);
%%
%[text] ## Plot
%%
fig = figure;
plot(t, u,     'k--',  'DisplayName', 'Desired (step)')
hold on
plot(t, y_lpf, 'b-',   'DisplayName', sprintf('LPF  \\tau = %.1f s', tau))
plot(t, y_rl,  'r-',   'DisplayName', sprintf('Rate limiter  R = %.2f/s', R))

% Mark the ramp-end time (where rate limiter reaches A, equivalent to tau)
xline(t_step + tau, 'r:', 'HandleVisibility', 'off')

xlabel('Time (s)',    'Interpreter', 'latex')
ylabel('Output',      'Interpreter', 'latex')
title( 'Rate Limiter vs.\ Low-Pass Filter (step input)', 'Interpreter', 'latex')
legend('Interpreter', 'tex', 'Location', 'southeast')
grid on
%%
%[text] ## Nonlinearity: Vary the Step Size
%[text] 
%[text] Hold $R$ fixed (as `ATC_ACCEL_MAX` is a fixed parameter) and vary the step
%[text] amplitude $A$.  The LPF response is unchanged (same $\\tau$), but the
%[text] rate-limiter ramp time $A/R$ scales with $A$.
%%
A_vals = [1, 3, 6];
colors_rl  = {'r-', 'm-', [0.8 0.2 0]};
colors_lpf = {'b-', 'c-', [0   0.4 0.8]};

fig2 = figure;
hold on
for i = 1:length(A_vals)
    Ai = A_vals(i);
    t_rel_i = max(t - t_step, 0);
    y_lpf_i = Ai * (1 - exp(-t_rel_i / tau));
    y_rl_i  = min(R * t_rel_i, Ai);

    c_lpf = colors_lpf{i};
    c_rl  = colors_rl{i};

    plot(t, y_lpf_i, 'Color', c_lpf, 'LineStyle', '-', ...
         'DisplayName', sprintf('LPF  A=%.0f', Ai))
    plot(t, y_rl_i,  'Color', c_rl,  'LineStyle', '--', ...
         'DisplayName', sprintf('Rate-lim  A=%.0f  (\\tau_{eq}=%.1fs)', Ai, Ai/R))
end

xlabel('Time (s)',  'Interpreter', 'latex')
ylabel('Output',    'Interpreter', 'latex')
title( 'Effect of step size: LPF (solid) vs.\ Rate Limiter (dashed)', ...
       'Interpreter', 'latex')
legend('Interpreter', 'tex', 'Location', 'southeast', 'FontSize', 8)
grid on

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:3d615c42]
%   data: {"dataType":"text","outputData":{"text":"Time constant tau = 2.00 s\n","truncated":false}}
%---
%[output:9ed71da0]
%   data: {"dataType":"text","outputData":{"text":"Step amplitude  A = 1.00\n","truncated":false}}
%---
%[output:798e5e05]
%   data: {"dataType":"text","outputData":{"text":"Rate limit      R = A\/tau = 0.5000 per second\n","truncated":false}}
%---
%[output:66de6dd2]
%   data: {"dataType":"error","outputData":{"errorType":"runtime","text":"Unrecognized function or variable 't_step'."}}
%---
