%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% An example of using the SKETCHBODE function for plotting both the Matlab
% Bode plot along with the straight-line (asymptotic) approximation.
%
% The SKETCHBODE function was originally written by Jeff DeCew for Feedback Controls
% at Olin College, Spring 2007.
%
% HISTORY
% 02.11.2007  bbing  Created example for distribution to Dynamics F07
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run each of these sections, one at a time, to see both the staightline
% approximationand the actual Bode plot.

%%
% Make a simple system first order system
figure(1)
sys1 = tf([1],[1 1]);
sketchbode(sys1);

%%
% Add some numerator dynamics
figure(2)
sys11 = tf([1 10],[1 1]);
sketchbode(sys11);

%%
% Now a second order system
figure(3)
wn = 1;
z = .1;
sys2nd = tf(wn^2,[1 2*z*wn wn^2 0]);
sketchbode(sys2nd)




%sketchbode(G)