# Assignment Outline — Frequency Response, Part 1 (Week 8)

Working draft (v1). The companion outline for Week 9 lives at
[../../w09_freq_response_part2/assignment/assignment_outline.md](../../w09_freq_response_part2/assignment/assignment_outline.md).

The two weeks split the chapter content as follows:

- **Week 8 (this outline):** anatomy of the Bode plot; sketching the
  frequency response of simple transfer functions from building blocks.
- **Week 9:** assessing dynamics from frequency response — open-loop margins
  for stability, and closed-loop magnitude for DC gain and bandwidth.

---

## 1. Current assignment

The committed [assignment_freq_response_part1.tex](assignment_freq_response_part1.tex)
contains seven exercises across four parts: hand evaluation, building-block
sketching, two Nise placeholders (10.1, 10.2), and MATLAB exploration. Per
the v1 review, **all Nise references will be replaced** with custom problems,
and the surge-bandwidth question will be moved to Week 9 (where bandwidth is
the headline concept).

---

## 2. Concept coverage map

The chapter [freq_response_part1.tex](../chapter/freq_response_part1.tex)
covers the following. The right column shows which proposed exercise (§3)
tests each.

| Concept | Tested in |
|---------|-----------|
| Sinusoidal steady state: $M(\omega)$, $\phi(\omega)$ | P1 |
| Evaluating $G(j\omega)$ at specific frequencies | P1 |
| dB and decade scales | P1, P2 |
| Bode form normalization (DC gain $K_0$ + unit-DC factors) | P2, P3 |
| Building blocks: $K$, $s$, $1/s$, $(s/a+1)$, $1/(s/a+1)$ | P2, P3, P5 |
| Second-order block (asymptote only — no peak correction) | P3 |
| Asymptotic magnitude sketching (slope changes at break frequencies) | P2, P3, P5 |
| Asymptotic phase sketching ($\pm 45°/$dec rule) | P2, P3, P5 |
| Comparing asymptote vs. exact (`sketchbode`) | P3, P5 |
| Reading DC gain and break frequency from a Bode plot | P4, P5 |
| Inverse direction: Bode plot → transfer function | P4 |

Concepts intentionally **not** tested:

- Peak-correction tables for second-order asymptotes (per chapter:
  "the sketches are learning tools — we always have computer tools").
- Closed-loop frequency response, margins, bandwidth (deferred to Week 9).
- Polar / Nyquist / Nichols plots (out of scope for the course).

---

## 3. Proposed exercises (all custom)

Five problems, ordered evaluation → sketching → reading. Each closes with a
short conceptual question (1–2 sentences expected).

### Problem 1 — *G(jω) by hand* (anchors the abstraction)

For the first-order plant
\[
  G(s) = \frac{10}{s + 10}
\]

a. Compute $G(j\omega)$, $|G(j\omega)|$ in dB, and $\angle G(j\omega)$ in
   degrees at $\omega = 1$, $10$, and $100$ rad/s. Show all work.
b. From those three points, infer the low-frequency asymptote (slope and
   value), the high-frequency asymptote (slope), and the break frequency.
c. *(Coda)* In one sentence, state the physical meaning of the break
   frequency for this system: what does an input at $\omega = 10$ rad/s
   look like at the output relative to one at $\omega = 1$?

**Concepts:** $G(j\omega)$ as a complex number; magnitude and phase; the dB
and degree conventions; reading the anatomy of a first-order response from
just a few evaluations.

### Problem 2 — *Bode form and sketch: first-order with a zero*

Given
\[
  G(s) = \frac{20(s+2)}{s+50}
\]

a. Convert to Bode form. Identify $K_0$ (in dB), and the normalized factors.
b. List the break frequencies and their slope contributions ($+20$ vs.\
   $-20$ dB/decade) for the magnitude.
c. Sketch the asymptotic magnitude and phase plots by hand. Label the
   low- and high-frequency slopes and the corner frequencies.
d. Verify with `bode()` in MATLAB. Where is the asymptote within 3 dB of
   the exact magnitude, and where is the difference largest?

**Concepts:** Bode form normalization; sum-of-blocks magnitude; phase as a
sum of $\pm 45°/$decade ramps; visual verification with MATLAB.

### Problem 3 — *Three plants, three sketches*

Convert to Bode form and sketch the asymptotic Bode magnitude plot for each.
Label all break frequencies, all asymptote slopes, and the low-frequency
intercept (in dB). Verify with `sketchbode()`.

a. $G_a(s) = \dfrac{100(s+1)}{s(s+10)}$ — Type 1, with a zero
b. $G_b(s) = \dfrac{50}{(s+2)(s+5)}$ — Type 0, two poles
c. $G_c(s) = \dfrac{400}{s^2 + 4s + 100}$ — second-order ($\omega_n=10$, $\zeta=0.2$)

For each, also sketch the phase plot (asymptotic, no peak correction for $G_c$).

*(Coda)* The asymptotic sketch of $G_c$ misses an important feature of the
exact response. In one sentence, name it and say roughly where it occurs.

**Concepts:** Three plant types in one problem (Type 1 with a zero, plain
Type 0, second-order). Limitations of the asymptotic approximation —
specifically, the resonance peak.

### Problem 4 — *Reading a Bode plot* (reverse direction)

Given the Bode magnitude plot below (placeholder — to be drawn or generated
from a known TF the students do not see):

- Low-frequency asymptote: $+20$ dB
- First break: $\omega_1 = 2$ rad/s, slope changes to $0$ dB/dec
- Second break: $\omega_2 = 30$ rad/s, slope changes to $-20$ dB/dec

a. What is the DC gain $K_0$ (linear units, not dB)?
b. How many poles and zeros does the transfer function have? Where are they?
c. Write a transfer function $G(s)$ in Bode form that produces this asymptote.
d. *(Coda)* Could a different transfer function produce the same magnitude
   asymptote? If yes, what makes them different? (Hint: think about the phase.)

**Concepts:** Reading slope changes as pole/zero locations; the DC gain
appears at the low-frequency asymptote; the magnitude asymptote does not
uniquely determine the TF — minimum-phase vs. nonminimum-phase pairs share
magnitude but differ in phase.

### Problem 5 — *USV surge: sketch by hand, verify in MATLAB*

The USV surge plant from the lab data:
\[
  G_{\mathrm{surge}}(s) = \frac{5.1}{1.3\,s + 1}
\]

a. Convert to Bode form and identify $K_0$ in dB and the break frequency
   in rad/s.
b. Sketch the asymptotic Bode magnitude and phase plots.
c. Use `sketchbode(G)` to overlay the asymptote on the exact response.
   Include the figure in your report.
d. From the plot, what is the magnitude (in dB) at the break frequency of
   the exact response? How far off is your asymptote?
e. *(Coda)* Connect this break frequency to last week's time-domain view:
   what is the time constant $\tau$, and how does it relate to the break
   frequency?

**Concepts:** Application to the lab plant; the connection between
$1/\tau$ in the time domain and the break frequency in the frequency
domain (the same number, same physical meaning).

---

## 4. Suggested final ordering

1. **Problem 1** — $G(j\omega)$ by hand (warm-up; anchors the abstraction)
2. **Problem 2** — One sketch with a zero (first encounter with $+20$ dB/dec)
3. **Problem 3** — Three sketches (Type 0, Type 1, second-order)
4. **Problem 4** — Reverse direction (Bode plot → TF)
5. **Problem 5** — USV surge (synthesis + tie back to time domain)

Rationale: starts with hand calculation to anchor what $G(j\omega)$ *is*,
then builds up to sketching multi-block transfer functions, then tests
fluency in the reverse direction, then closes with the lab plant. The
second-order sketch in P3 deliberately exposes the asymptote's blind spot
(the resonance peak), motivating Week 9's introduction to closed-loop
peaking.

---

## 5. Open questions for the next pass

- **Problem 4 plot generation** — Should the "given" Bode plot be hand-drawn
  in TikZ, or generated from a hidden TF in MATLAB and exported as a figure?
  Hand-drawn is cleaner asymptotes; MATLAB-generated tests reading from the
  exact response.
- **Problem 3, second-order block** — Is it pedagogically worth keeping
  the second-order plant in the sketching set when the chapter explicitly
  says "skip the corrections to second-order Bode plots"? The asymptotic
  sketch is fine; the question is whether the resonance gap is illuminating
  or confusing at this stage.
- **Problem 5 phase asymptote** — The first-order phase asymptote is the
  main source of error vs. the exact response (compared to magnitude).
  Worth a quantitative question on the phase error at $\omega = 1/\tau$?
- **Bandwidth question moved to Week 9** — Confirming the v1 plan: the
  surge $-3$ dB bandwidth question that was in Part 4 of the current
  assignment moves to Week 9, where bandwidth is the headline concept.
