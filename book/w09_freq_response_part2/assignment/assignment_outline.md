# Assignment Outline — Frequency Response, Part 2 (Week 9)

Working draft (v1). The companion outline for Week 8 lives at
[../../w08_freq_response_part1/assignment/assignment_outline.md](../../w08_freq_response_part1/assignment/assignment_outline.md).

The two weeks split the chapter content as follows:

- **Week 8:** anatomy of the Bode plot; sketching simple transfer functions.
- **Week 9 (this outline):** assessing dynamics from frequency response —
  open-loop margins (gain margin, phase margin) for stability and damping;
  closed-loop magnitude for DC gain and bandwidth.

The assignment leans toward **assessment** ("read these properties off the
plot") over **design** ("compute $K$ to meet a spec"). One gain-adjustment
problem at the end establishes the bridge to design, but the bulk of the
exercises are interpretive — taking a transfer function, drawing or
computing its Bode plot, and reading well-defined numbers from it.

---

## 1. Current assignment

The committed [assignment_freq_response_part2.tex](assignment_freq_response_part2.tex)
contains six exercises across four parts: reading margins, transient/frequency
correspondence, gain adjustment, and a USV margin question. Per the v1 review,
**all Nise references will be replaced** with custom problems, the
$\zeta \approx \mathrm{PM}/100$ approximation will be replaced by direct use
of the exact formula (Eq.\ 10.73), and a new problem on reading DC gain and
bandwidth from the closed-loop magnitude plot will be added.

---

## 2. Concept coverage map

The chapter [freq_response_part2.tex](../chapter/freq_response_part2.tex)
covers the following. The right column shows which proposed exercise (§3)
tests each.

| Concept | Tested in |
|---------|-----------|
| Nyquist criterion (named truth, no derivation) | P1 (coda), P2 |
| Gain crossover frequency $\omega_{\Phi_M}$ | P1, P2, P5 |
| Phase crossover frequency $\omega_{G_M}$ | P1, P2 |
| Reading phase margin $\Phi_M$ from a Bode plot | P1, P2, P3, P5 |
| Reading gain margin $G_M$ from a Bode plot | P1, P2 |
| Stability from the signs of $G_M$ and $\Phi_M$ | P1, P2 |
| Range of $K$ for stability (gain margin → $K_{\max}$) | P2 |
| Phase margin → damping ratio (Eq.\ 10.73) | P3 |
| Damping ratio → percent overshoot | P3 |
| Closed-loop magnitude: DC gain at low frequency | P4, P5 |
| Closed-loop magnitude: bandwidth at $-3$ dB | P4, P5 |
| Bandwidth as a measure of speed | P4 (coda) |
| Gain adjustment to set phase margin | P3 (final part) |

Concepts intentionally **not** tested:

- $M_p$, $\omega_p$ formulas for the closed-loop peak (mentioned in chapter
  for completeness, but the user said the closed-loop emphasis is "magnitude
  only for identifying DC gain and bandwidth").
- Bandwidth from the open-loop $-6$ to $-7.5$ dB rule (chapter sidebar — too
  approximate to drill on; closed-loop bandwidth is read directly from the
  closed-loop plot in this assignment).
- Lead, lag, lag-lead compensation (out of scope).

---

## 3. Proposed exercises (all custom)

Five problems, ordered reading-margins → range-of-K → spec-design →
closed-loop-reading → USV. Each closes with a short conceptual question.

### Problem 1 — *Read the margins*

The Bode plot below (placeholder) is the open-loop response of a
unity-feedback system with all open-loop poles in the left half-plane.

a. From the magnitude plot, identify the gain crossover frequency
   $\omega_{\Phi_M}$.
b. From the phase plot, identify the phase crossover frequency
   $\omega_{G_M}$.
c. Read off the gain margin $G_M$ (in dB) and the phase margin $\Phi_M$
   (in degrees).
d. Is the closed-loop system stable? Justify in one sentence using the
   margins you read.
e. *(Coda)* If the plant gain were doubled, what would happen to each of
   $\omega_{\Phi_M}$, $\omega_{G_M}$, $G_M$, and $\Phi_M$? Just say
   "increases", "decreases", or "unchanged" for each.

**Concepts:** The two crossover frequencies; reading margins; the effect
of gain scaling on the Bode plot (magnitude shifts, phase unchanged).

### Problem 2 — *Compute, then verify, then design for stability*

For each open-loop transfer function below, use MATLAB `margin()` to
compute $G_M$, $\Phi_M$, $\omega_{G_M}$, and $\omega_{\Phi_M}$. State
whether the closed loop is stable and explain.

a. $G(s) = \dfrac{100}{(s+1)(s+5)(s+10)}$
b. $G(s) = \dfrac{10}{s(s+2)(s+8)}$
c. $G(s) = \dfrac{K}{s(s+1)(s+4)}$ with $K = 1$

For part (c), additionally:

d. Find the maximum gain $K_{\max}$ that keeps the closed loop stable.
   (Hint: read $G_M$ in dB at $K = 1$.)
e. Verify with `margin()` at $K = K_{\max}$ — what do you expect both
   margins to be?

**Concepts:** Computing margins with MATLAB; using the gain margin in dB
to find the stability limit on $K$; recognizing marginal stability ($G_M = 0$).

### Problem 3 — *Phase margin → percent overshoot, then design $K$*

A unity-feedback system has open-loop transfer function
\[
  G(s) = \frac{K}{s(s+10)}
\]

a. For $K = 100$, compute the phase margin with `margin()`.
b. Use Eq.\ (10.73) from the chapter — solve numerically — to convert this
   phase margin to the predicted closed-loop damping ratio $\zeta$.
   Then convert $\zeta$ to a predicted percent overshoot.
c. Simulate the closed-loop step response with `step(feedback(G,1))` and
   measure the actual %OS. How well did the prediction match?
d. Design $K$ so the closed-loop %OS is approximately 10\%. (Procedure:
   %OS → $\zeta$ → required $\Phi_M$ from Eq.\ 10.73 → find $\omega^*$
   on the phase plot where $\angle G(j\omega^*) = \Phi_M - 180°$ →
   compute the gain shift needed to make $|G(j\omega^*)| = 1$.)
e. *(Coda)* The chapter says Eq.\ 10.73 is "exact for the pure second-order
   open loop" but only approximate for higher-order systems. The plant in
   this problem **is** pure second-order in $s$. Why might the prediction
   in (b) still be imperfect compared to simulation in (c)? (Hint: think
   about the closed loop, not just the open loop.)

**Concepts:** Phase margin → damping ratio → %OS chain; the gain
adjustment design procedure; the limits of the second-order approximation
even when the open-loop plant is itself second-order.

### Problem 4 — *Closed-loop magnitude: DC gain and bandwidth*

For the closed-loop system $T(s) = G(s) / (1 + G(s))$ with each open-loop
$G(s)$ below, plot the closed-loop magnitude $|T(j\omega)|$ vs.\ frequency
on a log scale. Read off (i) the DC gain (in linear units, not dB) and
(ii) the $-3$ dB bandwidth $\omega_{BW}$.

a. $G(s) = \dfrac{20}{s+10}$ (Type 0, first order)
b. $G(s) = \dfrac{50}{s(s+5)}$ (Type 1)
c. $G(s) = \dfrac{200}{(s+1)(s+10)(s+20)}$ (Type 0, third order)

Present your answers in a small table.

d. *(Coda)* For one of the systems above, the closed-loop DC gain is
   exactly 1 — for the other two it is less than 1. Which one, and what
   property of the open-loop transfer function explains it?

**Concepts:** Reading DC gain from the low-frequency plateau of $|T(j\omega)|$;
reading bandwidth as the $-3$ dB point; the connection between integrators
in the open loop and unity DC gain in the closed loop (Type 1 → $K_v$ finite,
$K_p = \infty$, so the closed loop tracks steps with zero error).

### Problem 5 — *USV surge: open-loop margin and closed-loop bandwidth*

The USV surge plant from the lab data:
\[
  G_{\mathrm{surge}}(s) = \frac{5.1}{1.3\,s + 1}
\]
A proportional controller $K_p$ closes the loop.

a. For $K_p = 1$, plot the open-loop Bode diagram. What is the phase margin?
   What is the gain margin? Justify your answer to the gain margin question
   in one sentence.
b. Plot the closed-loop magnitude response for $K_p = 1$, $K_p = 2$, and
   $K_p = 5$. For each, read off the closed-loop DC gain and the $-3$ dB
   bandwidth. Present in a table.
c. As $K_p$ increases, what happens to (i) the closed-loop DC gain (does
   it approach 1?), and (ii) the closed-loop bandwidth?
d. *(Coda)* From the lab data, the time-domain step response settled in
   about $4\tau \approx 5.2$ s. The bandwidth you found at $K_p = 1$
   should be consistent with this — explain the connection in one or two
   sentences.

**Concepts:** Margins of a first-order plant in unity feedback (infinite
$G_M$, large $\Phi_M$); how proportional gain trades closed-loop DC gain
(goes toward 1 as $K_p \to \infty$) for bandwidth (increases with $K_p$);
the time-domain / frequency-domain consistency of the surge dynamics.

---

## 4. Suggested final ordering

1. **Problem 1** — Read margins from a given plot (warm-up, no MATLAB)
2. **Problem 2** — Compute margins and find $K_{\max}$ (MATLAB confidence)
3. **Problem 4** — Closed-loop DC gain and bandwidth (assessment, no design)
4. **Problem 3** — Phase margin → %OS, then design (the design payoff)
5. **Problem 5** — USV synthesis: open-loop margin and closed-loop bandwidth

Rationale: starts with a no-MATLAB reading exercise to anchor the
margin definitions, builds up to MATLAB computation and stability-limit
analysis, then introduces the closed-loop magnitude assessment (DC gain,
bandwidth) before the design problem in P3, then finishes with the USV
plant tying margins and bandwidth together. The design problem is placed
fourth (not last) so it sits between the closed-loop assessment and the
USV synthesis.

---

## 5. Open questions for the next pass

- **Problem 1 plot source** — should the "given" Bode plot be hand-drawn
  asymptotes (cleaner reads, less ambiguous answers) or a MATLAB-generated
  plot of a hidden TF (more realistic but answers depend on plot
  resolution)?
- **Problem 3, part (e)** — the coda asks why the second-order prediction
  is imperfect. The honest answer is that closing the loop on a Type 1
  $G(s) = K/(s(s+10))$ does produce an exact second-order $T(s)$, so the
  match should be quite good. Is the question still interesting, or does
  it set up an answer that is actually "yes, the prediction is excellent"?
  Consider replacing with a third-order plant in (a)–(c) so the
  approximation has bite.
- **Problem 4, part (d)** — the unity-DC-gain plant is the Type 1 system
  (b). Worth swapping to a Type 0 with high open-loop DC gain (so
  closed-loop DC gain is close to but not exactly 1), to make the answer
  more nuanced?
- **MATLAB scope** — every problem after P1 uses MATLAB. Is that the right
  level, or should P3 (design) require a hand sketch step before the
  MATLAB verification?
- **Bandwidth from open-loop** — the chapter mentions the $-6$ to $-7.5$
  dB approximation for closed-loop bandwidth from the open-loop plot.
  Worth a sixth problem that uses it, or is it too approximate to drill on?
