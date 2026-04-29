G1 = tf(1,[10 1 0]);
Ge = feedback(0.1*G1,1);

G1 = tf(1,[10 1]);
Ge = feedback(10*G1,1);


figure(1)
step(Ge)
yline(1.0, "r--", 'LineWidth',1.5)
grid('on')


figure(2);
clf;
te = 100;
step(tf(1,[1 0])*Ge,te)
hold on
tt = linspace(0,te,100);
plot(tt,tt,"r--", 'LineWidth',1.5)
grid('on')
title ("Ramp Response")


figure(3);
clf;
step(tf(1,[1 0 0])*Ge,te)
hold on
plot(tt,tt.^2,"r--", 'LineWidth',1.5)
grid('on')
title ("Parabola Response")

fnames = ["step0.png", "ramp0.png", "para0.png"]
for ii = 1:3
    saveas(ii,fnames(ii))
end
