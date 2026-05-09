function out = normalize_pwm(pwm, inzero, inmax, inmin)
% NORMALIZE_PWM  Scale ArduPilot PWM (1000-2000) to normalized effort (-1..+1).
%   out = normalize_pwm(pwm, inzero, inmax, inmin)
%
%   Piecewise linear so asymmetric PWM ranges (RC*_MAX != 2*inzero - RC*_MIN)
%   still map to +/-1 at the endpoints:
%     pwm == inzero  -> 0
%     pwm == inmax   -> +1
%     pwm == inmin   -> -1

out = zeros(size(pwm));
pos = pwm >= inzero;
out( pos) = (pwm( pos) - inzero) / (inmax - inzero);
out(~pos) = (pwm(~pos) - inzero) / (inzero - inmin);
end
