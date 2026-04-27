% sse_companion.m  --  Steady-State Error Analysis companion script
% ME 2801 -- Controls Engineering
%
% Generates figures for sse_article.tex and demonstrates numerical methods.
% Run from hw5_steadystateerror/ so that images/ is a reachable relative path.
% Requires MATLAB R2020a+ for exportgraphics.

SAVE_FIGS = true;

%% ── Style ───────────────────────────────────────────────────────────────────
FW1 = 5.5;   FH1 = 2.6;   % single-panel (inches)
FW2 = 5.5;   FH2 = 4.8;   % two-panel stacked
FS  = 10;                  % axis/tick font size
LFS = 9;                   % legend font size

BLUE  = [0.15 0.35 0.75];
RED   = [0.80 0.20 0.10];
GREEN = [0.10 0.55 0.20];

if SAVE_FIGS && ~exist('images','dir'),  mkdir('images');  end  %#ok<UNRCH>
savepdf = @(fig,name) exportgraphics(fig, ...
    fullfile('images',[name '.pdf']), 'ContentType','vector');

%% ── Example systems ─────────────────────────────────────────────────────────
%
%  Type 0:  G0 = 20 / ((s+2)(s+4))
%           Kx = dcgain(G0) = 20/8 = 2.5
%           e_step = 1/(1+2.5) = 0.286
%
%  Type 1:  G1 = 10 / (s(s+5))
%           Kv = lim_{s->0} sG1(s) = 10/5 = 2
%           e_ramp = 1/2 = 0.5
%
%  Type 2:  G2 = 10(s+1)(s+2) / (s^2(s+3)(s+4))
%           Ka = lim_{s->0} s^2 G2(s) = 10*1*2/(3*4) = 5/3
%           e_ramp = 0  (K_v = inf),  e_para = 1/Ka = 0.6

G0 = tf(20, conv([1 2],[1 4]));
G1 = tf(10, conv([1 0],[1 5]));
G2 = tf(10*conv([1 1],[1 2]), conv([1 0 0], conv([1 3],[1 4])));

T0 = feedback(G0, 1);
T1 = feedback(G1, 1);
T2 = feedback(G2, 1);

%% ── Static error constants ──────────────────────────────────────────────────
%
% Kx = lim_{s->0} G(s)       = dcgain(G)
% Kv = lim_{s->0} sG(s)      = dcgain(minreal(s*G))
% Ka = lim_{s->0} s^2*G(s)   = dcgain(minreal(s^2*G))
%
% minreal cancels any pole-zero pair at the origin before dcgain evaluates.
% For Type 0: Kv=0, Ka=0   (no integrators)
% For Type 1: Kx=Inf, Ka=0
% For Type 2: Kx=Inf, Kv=Inf

s  = tf([1 0], 1);   % transfer function for the variable s
s2 = tf([1 0 0], 1);

Kx = @(G) dcgain(G);
Kv = @(G) dcgain(minreal(s*G));
Ka = @(G) dcgain(minreal(s2*G));

fprintf('--- Static error constants ---\n')
fprintf('Type 0:  Kx = %5.2f,  Kv = %5.2f,  Ka = %5.2f\n', ...
    Kx(G0), Kv(G0), Ka(G0))
fprintf('Type 1:  Kx = %5s,   Kv = %5.2f,  Ka = %5.2f\n', ...
    'Inf', Kv(G1), Ka(G1))
fprintf('Type 2:  Kx = %5s,   Kv = %5s,   Ka = %5.3f\n', ...
    'Inf', 'Inf', Ka(G2))

fprintf('\n--- Steady-state errors (unit inputs) ---\n')
fprintf('Type 0:  e_step = %.4f,  e_ramp = Inf,  e_para = Inf\n', ...
    1/(1 + Kx(G0)))
fprintf('Type 1:  e_step = 0,      e_ramp = %.4f, e_para = Inf\n', ...
    1/Kv(G1))
fprintf('Type 2:  e_step = 0,      e_ramp = 0,     e_para = %.4f\n', ...
    1/Ka(G2))

%% ── fig:sse_step_compare  (step response, Type 0 vs Type 1) ─────────────────
t = 0:0.02:8;

f1 = mkfig(1, FW2, FH2);

subplot(2,1,1)
hold on;  box on;  grid on
plot(t, ones(size(t)), 'k--', 'HandleVisibility','off')
plot(t, step(T0,t), 'Color',BLUE, 'DisplayName','output y(t)')
Kx0 = Kx(G0);
ess0 = 1/(1 + Kx0);
yline(1 - ess0, 'r--', sprintf('y_{ss} = %.3f', 1-ess0), ...
    'LabelHorizontalAlignment','left', 'LabelVerticalAlignment','bottom', ...
    'FontSize', LFS, 'Color', RED)
ylabel('y(t)  [unit step in]', 'FontSize', FS)
title(sprintf('Type 0:  K_x = %.1f,  e_{step} = 1/(1+K_x) = %.3f', ...
    Kx0, ess0), 'FontSize', FS, 'Interpreter','tex')
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast')
set(gca,'FontSize',FS);  xlim([0 8]);  ylim([0 1.15])

subplot(2,1,2)
hold on;  box on;  grid on
plot(t, ones(size(t)), 'k--', 'HandleVisibility','off')
plot(t, step(T1,t), 'Color',RED, 'DisplayName','output y(t)')
ylabel('y(t)  [unit step in]', 'FontSize', FS)
xlabel('Time (s)', 'FontSize', FS)
title('Type 1:  K_x = \infty,  e_{step} = 0', ...
    'FontSize', FS, 'Interpreter','tex')
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast')
set(gca,'FontSize',FS);  xlim([0 8]);  ylim([0 1.5])

if SAVE_FIGS, savepdf(f1,'sse_step_compare'); end  %#ok<UNRCH>

%% ── fig:sse_ramp_compare  (ramp response, Type 0 / 1 / 2) ──────────────────
t = 0:0.05:25;
r = t;   % unit ramp r(t) = t

y0r = lsim(T0, r, t);
y1r = lsim(T1, r, t);
y2r = lsim(T2, r, t);

Kv1 = Kv(G1);

f2 = mkfig(2, FW1, FH1*2.0);
hold on;  box on;  grid on
plot(t, r,   'k--',         'DisplayName','reference  r(t) = t')
plot(t, y0r, 'Color',RED,   'DisplayName','Type 0  (e_{\infty} = \infty)')
plot(t, y1r, 'Color',BLUE,  'DisplayName', ...
    sprintf('Type 1  (e_{\\infty} = 1/K_v = %.2f)', 1/Kv1))
plot(t, y2r, 'Color',GREEN, 'DisplayName','Type 2  (e_{\infty} = 0)')

xlabel('Time (s)', 'FontSize', FS)
ylabel('Output', 'FontSize', FS)
legend('Interpreter','tex', 'FontSize',LFS, 'Location','northwest')
set(gca,'FontSize',FS);  xlim([0 25]);  ylim([0 27])

if SAVE_FIGS, savepdf(f2,'sse_ramp_compare'); end  %#ok<UNRCH>

%% ── fig:sse_design  (design example with K = 400) ───────────────────────────
%
% G(s) = K(s+3) / (s(s+6)(s+10))
% Kv   = K*3/(6*10) = K/20
% Spec: e_ramp = 5% => Kv = 20 => K = 400

K_des = 400;
G_des = tf(K_des*[1 3], conv([1 0], conv([1 6],[1 10])));
T_des = feedback(G_des, 1);

fprintf('\n--- Design example  (K = %d) ---\n', K_des)
fprintf('Poles: '); fprintf('  %.3f', real(pole(T_des))); fprintf('\n')
Kv_des = Kv(G_des);
fprintf('Kv = %.1f,  e_ramp = %.4f  (%.1f%%)\n', Kv_des, 1/Kv_des, 100/Kv_des)

t3 = 0:0.05:15;
r3 = t3;
y3 = lsim(T_des, r3, t3);

f3 = mkfig(3, FW1, FH1*1.3);
hold on;  box on;  grid on
plot(t3, r3, 'k--', 'DisplayName','reference  r(t) = t')
plot(t3, y3, 'Color',BLUE, 'DisplayName','output  y(t)')

% Mark the steady-state error gap near the end
te = t3(end);
ye = y3(end);
re = r3(end);
plot([te te], [ye re], 'r-', 'LineWidth', 1.2, 'HandleVisibility','off')
text(te - 1.8, (ye+re)/2, sprintf('e_{ss} = %.2f', re-ye), ...
    'Color', RED, 'FontSize', LFS, 'Interpreter','tex')

xlabel('Time (s)', 'FontSize', FS)
ylabel('Position', 'FontSize', FS)
title(sprintf('Design example: K = %d  \\Rightarrow  K_v = %.0f,  e_{ramp} = 5%%', ...
    K_des, Kv_des), 'FontSize', FS, 'Interpreter','tex')
legend('Interpreter','tex', 'FontSize',LFS, 'Location','northwest')
set(gca,'FontSize',FS)

if SAVE_FIGS, savepdf(f3,'sse_design'); end  %#ok<UNRCH>

%% ── fig:sse_integrator_adapt  (integrator adaptation, P vs PI) ──────────────
%
% Surge plant: G_v = 2.2/(1.5s+1)  (same as PID article)
% P only:  Kp = 1.0   (Type 0, finite step error)
% PI:      Kp = 0.405, Ki = 0.553  (Type 1, wn=0.9, zeta=0.70 -- from PID article)

K_v  = 2.2;   tau_v = 1.5;
G_surge = tf(K_v, [tau_v 1]);

Kp_P  = 1.0;
Kp_PI = 0.405;   Ki_PI = 0.553;

C_PI_surge = tf([Kp_PI Ki_PI], [1 0]);

T_P_surge  = feedback(Kp_P * G_surge, 1);
T_PI_surge = feedback(C_PI_surge * G_surge, 1);

t4   = 0:0.02:12;
r4   = ones(size(t4));        % unit step

y_P_s  = step(T_P_surge,  t4);
y_PI_s = step(T_PI_surge, t4);

e_P_s  = r4' - y_P_s;
e_PI_s = r4' - y_PI_s;

u_I = Ki_PI * cumtrapz(t4, e_PI_s);   % integrator state = Ki * integral(e dt)

f4 = mkfig(4, FW2, FH2);

subplot(2,1,1)
hold on;  box on;  grid on
plot(t4, e_P_s,  'Color',RED,  'DisplayName', ...
    sprintf('P only  (e_{ss} = %.2f)', 1/(1+Kp_P*K_v)))
plot(t4, e_PI_s, 'Color',BLUE, 'DisplayName','PI  (e_{ss} = 0)')
yline(0, 'k--', 'HandleVisibility','off')
ylabel('Error  e(t)', 'FontSize', FS)
title('Integrator adaptation (surge plant, unit step)', 'FontSize', FS)
legend('Interpreter','tex', 'FontSize',LFS, 'Location','northeast')
set(gca,'FontSize',FS);  xlim([0 12])

subplot(2,1,2)
hold on;  box on;  grid on
plot(t4, u_I, 'Color',BLUE, 'DisplayName','u_{I}(t)  (integrator state, PI only)')
yline(0, 'k--', 'HandleVisibility','off')
xlabel('Time (s)', 'FontSize', FS)
ylabel('Integrator state  u_I(t)', 'FontSize', FS)
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast')
set(gca,'FontSize',FS);  xlim([0 12])

if SAVE_FIGS, savepdf(f4,'sse_integrator_adapt'); end  %#ok<UNRCH>

%% ── fig:sse_ff_compare  (P / PI / P+FF / PI+FF step responses) ──────────────

K_plant = K_v;   % 2.2 -- plant DC gain; used for feedforward gain 1/K_plant

T_PFF  = G_surge * (Kp_P  + 1/K_plant) / (1 + Kp_P  * G_surge);
T_PIFF = G_surge * (C_PI_surge + 1/K_plant) / (1 + C_PI_surge * G_surge);

fprintf('\n--- Feedforward comparison (DC gains, should all be 1 except P) ---\n')
fprintf('P:      DC gain = %.4f  (e_ss = %.4f)\n', dcgain(T_P_surge),  1-dcgain(T_P_surge))
fprintf('PI:     DC gain = %.4f  (e_ss = 0)\n',    dcgain(T_PI_surge))
fprintf('P+FF:   DC gain = %.4f  (e_ss = 0)\n',    dcgain(T_PFF))
fprintf('PI+FF:  DC gain = %.4f  (e_ss = 0)\n',    dcgain(T_PIFF))

t5 = 0:0.02:12;
y_P5    = step(T_P_surge,  t5);
y_PI5   = step(T_PI_surge, t5);
y_PFF5  = step(T_PFF,      t5);
y_PIFF5 = step(T_PIFF,     t5);

ORANGE = [0.90 0.50 0.05];

f5 = mkfig(5, FW1*1.05, FH1*1.8);
hold on;  box on;  grid on
plot(t5, ones(size(t5)), 'k--', 'HandleVisibility','off')
plot(t5, y_P5,    'Color',RED,    'LineStyle','-',  ...
    'DisplayName', sprintf('P only  (e_{ss} = %.2f)', 1-dcgain(T_P_surge)))
plot(t5, y_PI5,   'Color',BLUE,   'LineStyle','-',  'DisplayName','PI')
plot(t5, y_PFF5,  'Color',GREEN,  'LineStyle','--', 'DisplayName','P + FF')
plot(t5, y_PIFF5, 'Color',ORANGE, 'LineStyle','--', 'DisplayName','PI + FF')

xlabel('Time (s)', 'FontSize', FS)
ylabel('Speed  y(t)  (m/s)', 'FontSize', FS)
title('Step response: four controller architectures', 'FontSize', FS)
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast')
set(gca,'FontSize',FS);  xlim([0 12]);  ylim([0 1.35])

if SAVE_FIGS, savepdf(f5,'sse_ff_compare'); end  %#ok<UNRCH>

%% ── Local functions ─────────────────────────────────────────────────────────
function f = mkfig(num, w, h)
    f = figure(num);
    clf(f, 'reset');
    set(f, 'Units','inches','Position',[1 1 w h], ...
           'PaperUnits','inches','PaperSize',[w h], ...
           'PaperPosition',[0 0 w h]);
end
