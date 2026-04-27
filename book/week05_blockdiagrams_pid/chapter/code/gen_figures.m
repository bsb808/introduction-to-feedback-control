% gen_figures.m  –  Generate all placeholder figures for blockdiagrams_pid.tex
%
% Writes PDFs to ../images/ (resolved relative to this script's location),
% so it can be invoked from any working directory.
% Requires MATLAB R2020a+ for exportgraphics.
%
% Plant parameters (nominal):
%   Surge:     K_v = 2.2,  tau_v = 1.5 s   =>  G_v(s) = 2.2 / (1.5s + 1)
%   Yaw-rate:  K_r = 0.5,  tau_r = 0.6 s   =>  G_r(s) = 0.5 / (0.6s + 1)

SAVE_FIGS = true %false;   % set true to export PDFs to images/

%% ── Plant models ────────────────────────────────────────────────────────────
K_v = 2.2;   tau_v = 1.5;
K_r = 0.5;   tau_r = 0.6;

G_v = tf(K_v, [tau_v 1]);
G_r = tf(K_r, [tau_r 1]);

%% ── Style constants ─────────────────────────────────────────────────────────
FW1 = 5.5;   FH1 = 2.6;   % single-panel (width x height, inches)
FW2 = 5.5;   FH2 = 4.5;   % two-panel stacked
FS  = 10;                  % axis label / tick font size
LFS = 9;                   % legend font size

BLUE = [0.15 0.35 0.75];
RED  = [0.80 0.20 0.10];

images_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'images');
if SAVE_FIGS && ~exist(images_dir,'dir'),  mkdir(images_dir);  end  %#ok<UNRCH>
savepdf = @(fig,name) exportgraphics(fig, fullfile(images_dir,[name '.pdf']), 'ContentType','vector');

%% ── fig:p_step ──────────────────────────────────────────────────────────────
% P-only step response family on surge plant (unit step r = 1).
% Four values of K_P, each settling below 1 by e_ss = 1/(1 + K_P*K_v).

KP_vals = [0.3  0.7  1.5  4.0];
blues   = [0.7  0.8  1.00;   % lightest
           0.45 0.62 0.90;
           0.20 0.40 0.78;
           0.00 0.15 0.55];  % darkest
t1 = 0:0.005:10;

f1 = mkfig(1, FW1, FH1);
hold on;  box on;  grid on;
plot(t1, ones(size(t1)), 'k--', 'HandleVisibility','off');
for i = numel(KP_vals):-1:1
    KP   = KP_vals(i);
    T_cl = feedback(KP*G_v, 1);
    ess  = 1 / (1 + KP*K_v);
    plot(t1, step(T_cl, t1), 'Color',blues(i,:), ...
        'DisplayName', sprintf('K_P = %.1f,  e_{ss} = %.2f', KP, ess));
end
xlabel('Time (s)', 'FontSize',FS);
ylabel(['Speed, $r(t) = \mu(t)$, (m/s)'], 'FontSize',FS, 'Interpreter','latex');
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast');
set(gca, 'FontSize',FS);
xlim([0 10]);  ylim([0 1.12]);

if SAVE_FIGS, savepdf(f1,'p_step'); end  %#ok<UNRCH>

%% ── fig:pi_compare ──────────────────────────────────────────────────────────
% P-only (K_P = 1) vs. PI (zeta = 0.70, wn = 0.9 rad/s) on surge plant.
% PI gains from eqs. (pi_params): K_I = wn^2*tau/K, K_P = (2*zeta*wn*tau-1)/K.

KP_p    = 1.0;
T_Ponly = tf(KP_p*K_v, [tau_v, 1 + KP_p*K_v]);

wn   = 0.9;   zeta = 0.70;
KI_pi = wn^2 * tau_v / K_v;
KP_pi = (2*zeta*wn*tau_v - 1) / K_v;
C_pi  = tf([KP_pi KI_pi], [1 0]);
T_PI  = feedback(C_pi * G_v, 1);

t2 = 0:0.02:15;

f2 = mkfig(2, FW1, FH1);
hold on;  box on;  grid on;
plot(t2, ones(size(t2)), 'k--', 'HandleVisibility','off');
plot(t2, step(T_Ponly, t2), 'Color',BLUE, ...
    'DisplayName', sprintf('P only (K_P = %.1f, e_{ss} = %.2f)', ...
    KP_p, 1/(1 + KP_p*K_v)));
plot(t2, step(T_PI, t2), 'Color',RED, ...
    'DisplayName', sprintf('PI (K_P = %.2f, K_I = %.2f)', KP_pi, KI_pi));
xlabel('Time (s)', 'FontSize',FS);
ylabel(['Speed, $r(t) = \mu(t)$, (m/s)'], 'FontSize',FS, 'Interpreter','latex');
legend('Interpreter','tex', 'FontSize',LFS, 'Location','southeast');
set(gca, 'FontSize',FS);
xlim([0 15]);  ylim([0 1.35]);

if SAVE_FIGS, savepdf(f2,'pi_compare'); end  %#ok<UNRCH>

%% ── fig:windup ──────────────────────────────────────────────────────────────
% Euler simulation: PI with NO anti-windup on surge plant.
%   r = 1.8 m/s (achievable; K_v = 2.2 m/s at full throttle)
%   Saturation: u in [0, 1]  (forward throttle only)
%   K_P = 1.2, K_I = 0.8 => P-term alone saturates initially, causing windup.

dt3  = 0.005;   
Tsim = 15;
tt3  = 0:dt3:Tsim;   
N3 = numel(tt3);

r_w  = 1.8;   KP_w = 1.2;   KI_w = 0.8;
u_hi = 1.0;   u_lo = 0.0;

yy  = zeros(1,N3);   ee  = zeros(1,N3);
xi_ = zeros(1,N3);   ur  = zeros(1,N3);

xp = 0;   xi = 0;
for k = 1:N3
    yy(k)  = xp;
    ee(k)  = r_w - xp;
    xi     = xi + ee(k)*dt3;
    u_raw  = KP_w*ee(k) + KI_w*xi;
    u_sat  = min(max(u_raw, u_lo), u_hi);
    xi_(k) = xi;
    ur(k)  = u_raw;
    xp     = xp + dt3 * (-xp + K_v*u_sat) / tau_v;
end

f3 = mkfig(3, FW2, FH2);

subplot(2,1,1);
hold on;  box on;  grid on;
patch([tt3, fliplr(tt3)], [max(ee,0), zeros(1,N3)], ...
    [0.75 0.85 1.0], 'EdgeColor','none','FaceAlpha',0.55,'HandleVisibility','off');
patch([tt3, fliplr(tt3)], [min(ee,0), zeros(1,N3)], ...
    [1.0 0.75 0.75], 'EdgeColor','none','FaceAlpha',0.55,'HandleVisibility','off');
plot(tt3, ee, 'Color',BLUE, 'DisplayName','$e(t)$');
plot(tt3, zeros(1,N3), 'k-', 'HandleVisibility','off');
ylabel('Error $e$ (m/s)', 'FontSize',FS, 'Interpreter','latex');
legend('Interpreter','latex', 'FontSize',LFS, 'Location','northeast');
set(gca, 'FontSize',FS);   xlim([0 Tsim]);

subplot(2,1,2);
hold on;  box on;  grid on;
plot(tt3, xi_, 'Color',BLUE, 'DisplayName','$\int e\,\mathrm{d}t$');
plot(tt3, ur,  'Color',RED, 'LineStyle','--', 'DisplayName','$u_{\rm raw}$');
plot([0 Tsim],[u_hi u_hi], 'k:', 'HandleVisibility','off');
plot([0 Tsim],[u_lo u_lo], 'k:', 'HandleVisibility','off');
xlabel('Time (s)', 'FontSize',FS);
ylabel('Value', 'FontSize',FS);
legend('Interpreter','latex', 'FontSize',LFS, 'Location','northeast');
set(gca, 'FontSize',FS);   xlim([0 Tsim]);

if SAVE_FIGS, savepdf(f3,'windup'); end  %#ok<UNRCH>

%% ── fig:d_noise ─────────────────────────────────────────────────────────────
% Illustrate sensor noise amplification by the derivative term.
% True speed: first-order step response of surge plant at u = 0.5.
% Measurement: true speed + white noise (simulating GPS at 20 Hz).
% Derivative: finite difference of the noisy measurement.

rng(7);                          % reproducible noise
dt4 = 0.05;   Tn = 12;          % 20 Hz sample rate, 12 s window
tt4 = 0:dt4:Tn;   N4 = numel(tt4);

y_true = K_v * 0.5 * (1 - exp(-tt4 / tau_v));
y_meas = y_true + 0.025*randn(1, N4);

dy   = diff(y_meas) / dt4;
tt_d = tt4(1:end-1) + dt4/2;    % midpoint timestamps for derivative
dy_true = diff(y_true) / dt4;
f4 = mkfig(4, FW2, FH2);

subplot(2,1,1);
hold on;  box on;  grid on;
plot(tt4, y_true, 'k--', 'DisplayName','modeled');
plot(tt4, y_meas, 'Color',BLUE, 'DisplayName','measured');
ylabel('Speed, $u(t)$ (m/s)', 'FontSize',FS, 'Interpreter','latex');
legend('Interpreter','latex', 'FontSize',LFS, 'Location','southeast');
set(gca, 'FontSize',FS);   xlim([0 Tn]);

subplot(2,1,2);
hold on;  box on;  grid on;
%plot(tt_d, zeros(1,numel(tt_d)), 'k-', 'HandleVisibility','off');
plot(tt_d, dy_true, 'k-', 'DisplayName','modeled');
plot(tt_d, dy, 'Color',BLUE, 'DisplayName','measured');
xlabel('Time (s)', 'FontSize',FS);
ylabel('$\dot{u}$ (m/s$^2$)', 'FontSize',FS, 'Interpreter','latex');
legend('Interpreter','latex', 'FontSize',LFS, 'Location','southeast');
set(gca, 'FontSize',FS);   xlim([0 Tn]);

if SAVE_FIGS, savepdf(f4,'d_noise'); end  %#ok<UNRCH>

%% ── Local functions ─────────────────────────────────────────────────────────

function f = mkfig(num, w, h)
% Create (or reuse) figure NUM, clear it, and set print dimensions.
    f = figure(num);
    clf(f, 'reset');
    set(f, 'Units','inches','Position',[1 1 w h], ...
           'PaperUnits','inches','PaperSize',[w h],'PaperPosition',[0 0 w h]);
end
