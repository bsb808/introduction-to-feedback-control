
% USV Example
K = 2
wc = 0.1;
G = K*tf(wc,[1 wc]);
figure(1)
clf()

%BodePaper(0.001,10,-40,10,-90,0)

sketchbode(G);

ww = [0.01, 0.1, 1, 10];
[m,p]=bode(G,ww);

hold on
subplot(2,1,2)
semilogx(ww,squeeze(p), 'sk', 'MarkerFaceColor','k', 'MarkerSize',12)
%% 
hold on
subplot(211)
hold on
semilogx(ww,20*log10(squeeze(m)), 'sk', 'MarkerFaceColor','k', 'MarkerSize',12)
