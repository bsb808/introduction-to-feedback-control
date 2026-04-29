%[text] # Week 2 MATLAB Companion: Transfer Functions
%[text] This script follows the examples in the chapter, showing how to create and work with transfer function objects in MATLAB's Control System Toolbox.
%%
%[text] ## Creating Transfer Functions with `tf()`
%[text] The `tf()` function takes numerator and denominator coefficient vectors in descending powers of $s$.  We can represent polynomials in MATLAB as vectors of the coefficients.  
%%
%[text] **Example 1** — first-order system $G(s) = \\frac{1}{s+2}$
num1 = [1];
den1 = [1, 2];
G1 = tf(num1, den1)
%%
%[text] **Example 2** — second-order system $G(s) = \\frac{2s+1}{s^2+5s+6}$
num2 = [2, 1];
den2 = [1, 5, 6];
G2 = tf(num2, den2)
%%
%[text] **Example 3** — third-order system $G(s) = \\frac{3s^2+1}{s^3+4s^2+5s+2}$
num3 = [3, 0, 1];
den3 = [1, 4, 5, 2];
G3 = tf(num3, den3)
%%
%[text] ## Poles and Zeros
%[text] Poles are roots of the denominator; zeros are roots of the numerator.
%[text] They determine the character of the system response.
p2 = pole(G2)
z2 = zero(G2)
%%
%[text] `pzplot` displays poles (x) and zeros (o) in the $s$-plane.
pzplot(G2)
grid on
title('Pole-zero map: Example 2')
%%
%[text] ## Zero-Pole-Gain Form with `zpk()`
%[text] `zpk()` represents the transfer function in factored form:
%[text] $G(s) = k \\frac{(s-z\_1)(s-z\_2)\\cdots}{(s-p\_1)(s-p\_2)\\cdots}$
%[text] This is often more revealing than the polynomial form.
G2_zpk = zpk(G2)
%%
%[text] ## Standard Responses
%[text] Once `G` is defined, the Control System Toolbox computes standard responses directly — no partial fractions needed.
%%
%[text] **Step response** — output when input is a unit step $u(t)$
figure
step(G1, G2)
legend('G1 (1st order)', 'G2 (2nd order)')
title('Step responses')
%%
%[text] **Impulse response**
figure
impulse(G1, G2)
legend('G1', 'G2')
title('Impulse responses')
%%
%[text] ## Using the Transfer Function: $C(s) = G(s)R(s)$
%[text] Multiplying transfer functions in MATLAB uses `*`.Here we find the output for a ramp input $R(s) = 1/s^2$ applied to Example 1.
R = tf(1, [1, 0, 0]);   % 1/s^2  (ramp)
C = G1 * R
%%
%[text] The output $C(s)$ can be inverted numerically with `impulse` on a related system, or inspected via `pole` and `residue`.
pole(C)
[r, p, k] = residue(C.Numerator{1}, C.Denominator{1})

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
