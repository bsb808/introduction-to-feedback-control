%% 
% Type 1

Kdc = 5;
omega_n = 10;
zeta = 0.9;
Gol = tf(Kdc*omega_n^2,[1 2*zeta*omega_n omega_n^2]);
%step(Gol)
figure(1);
clf
Gcl = feedback(Gol, 1);
[y,t] = step(Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
yline(1,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Step Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')

%%
figure
clf
Gcl = feedback(Gol, 1);
[y,t] = step(tf([1],[1 0])*Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
plot(y,y,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Ramp Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')

%% 
% 

figure
clf;
Gcl = feedback(Gol, 1);
[y,t] = step(tf([1],[1 0 0])*Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
plot(y,y.^2,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Parabola Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')

%% 
% Type 1

Kdc = 3;
omega_n = 10;
zeta = 0.9;
Gol = tf(Kdc*omega_n^2,[1 2*zeta*omega_n omega_n^2 0]);
%step(Gol)
figure(1);
clf
Gcl = feedback(Gol, 1);
[y,t] = step(Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
yline(1,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Step Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')

%%
figure
clf
Gcl = feedback(Gol, 1);
[y,t] = step(tf([1],[1 0])*Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
plot(y,y,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Ramp Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')

%% 
% 

figure
clf;
Gcl = feedback(Gol, 1);
[y,t] = step(tf([1],[1 0 0])*Gcl);
plot(t,y, 'DisplayName',"Output", 'LineWidth',2);
hold on
plot(y,y.^2,'r--', "DisplayName","Input", 'LineWidth',2);
title('Closed-Loop Unit Parabola Response')
grid('on')
xlabel("Time (s)")
ylabel("Response (n/a)")
ylim([0 1.1])
legend('location','northwest')