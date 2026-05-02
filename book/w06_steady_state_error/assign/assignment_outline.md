# Assignment Outline — Steady-State Error (Week 6)

Working draft (v2, after first review pass). All Nise problems will be replaced
with custom equivalents; standalone written questions removed; disturbance
exercise dropped; USV exercises moved to current week-5 numerical plant.

---

## 1. Current assignment

The committed [assign_steady_state_error.tex](assign_steady_state_error.tex)
contains four exercises (Nise 7.5, 7.10, 7.17, plus a symbolic USV case
study). Per the v1 review, **all four will be replaced** — the textbook
exercises with custom problems modeled on the same concepts, and the symbolic
USV case study with concrete exercises tied to the week-5 surge plant numbers.

---

## 2. Concept coverage map

The chapter [steady_state_error.tex](../chapter/steady_state_error.tex) covers
the following. The right column shows which proposed exercise (§3) tests each.

| Concept | Tested in |
|---------|-----------|
| Master equation $e(\infty) = \lim sR(s)/(1+G(s))$ | P1, P2, P3, P4 |
| System type identification by inspection | P1, P4 |
| Static error constants $K_x$, $K_v$, $K_a$ | P1, P3 |
| Step / ramp / parabola SSE pattern | P1, P4 |
| Type-vs-input diagonal pattern | P4 (table) |
| Bridge to transient (overshoot, settling time) | P2 |
| Design: solve for gain to meet a spec | P3 |
| Stability is a precondition for the formula | P3 (coda) |
| Overloaded notation $G(s) = C(s)P(s)$ | P6 (coda) |
| Integrator adaptation argument | P5 (coda) |
| Integrator increments Type by 1 | P5 |
| Feedforward does *not* change Type | P5 |
| PI + feedforward combined architecture | P5 |

Concepts intentionally **not** tested:
- Disturbance rejection (out of scope per v1 review)
- Velocity error / derivation of velocity-error tables (was Nise 7.17 — too confusing)
- MATLAB `minreal` for cancelling pole–zero pairs (always confusing — students compute $K_v$, $K_a$ by hand)

---

## 3. Proposed exercises (all custom)

Six problems, ordered concrete → design → USV. Each closes with a short
conceptual question (1–2 sentences expected).

### Problem 1 — *SSE for a Type 0 plant* (modeled on Nise 7.5)

Given the unity-feedback system with
\[
  G(s) = \frac{600}{(s+10)(s^2 + 4s + 25)}
\]

a. Identify the system Type by inspection.
b. Compute $K_x$, $K_v$, $K_a$.
c. Find the steady-state error for inputs $u(t)$, $t\,u(t)$, and $\tfrac{1}{2}t^2 u(t)$.
d. *(Coda)* Two of your three answers in (c) are infinite. In one sentence,
   explain what physical fact about $G(s)$ makes that so.

**Concepts:** Type identification, error constants, the master equation
applied three times.

### Problem 2 — *Type 1 with transient* (modeled on Nise 7.10)

Given the unity-feedback system with
\[
  G(s) = \frac{4000}{s(s+60)}
\]

a. What is the percent overshoot for a unit step input? (Recall week 4.)
b. What is the 2% settling time?
c. Find the steady-state error for $5u(t)$, $5tu(t)$, and $5t^2u(t)$.
d. *(Coda)* Suppose you want to reduce the ramp error by raising the loop
   gain. In one or two sentences, explain why this might be a bad idea —
   referencing your answer to (a).

**Concepts:** Bridge from transient (week 4) to steady-state; the inherent
tradeoff between speed/overshoot and steady-state accuracy.

### Problem 3 — *Design for a spec* (modeled on Nise 7.18a / 7.20)

The forward-path transfer function of a unity-feedback position-control
system is
\[
  G(s) = \frac{K(s+5)}{s(s+8)(s+12)}
\]

a. What is the system Type?
b. Find the value of $K$ such that the steady-state error to a unit ramp
   input is 4%.
c. *(Coda)* What single assumption from the chapter must hold for your
   value of $K$ to be a meaningful answer? In practice, what would you
   verify before deploying this controller?

**Concepts:** Design procedure (Section 8 of chapter); stability as a
precondition.

### Problem 4 — *Fill the table* (replaces Nise 7.17, no derivation)

For each of the three plants below, fill in the table cell with the
steady-state error: a number, $0$, or $\infty$.

\[
  G_a(s) = \frac{20}{(s+2)(s+10)}, \quad
  G_b(s) = \frac{40}{s(s+8)}, \quad
  G_c(s) = \frac{50(s+1)}{s^2(s+10)}
\]

|              | $r(t) = u(t)$ | $r(t) = tu(t)$ | $r(t) = \tfrac12 t^2 u(t)$ |
|--------------|---------------|----------------|----------------------------|
| $G_a(s)$     |               |                |                            |
| $G_b(s)$     |               |                |                            |
| $G_c(s)$     |               |                |                            |

a. Identify the Type of each plant before computing.
b. Fill the nine cells.
c. *(Coda)* Describe the diagonal pattern in your table in one sentence.

**Concepts:** The type-vs-input diagonal pattern (Section 6 of chapter)
visualized concretely. No new math, just nine applications of the master
equation.

### Problem 5 — *USV surge: predict before you simulate*

The USV's surge (forward-speed) plant from week 5:
\[
  G_\mathrm{surge}(s) = \frac{5.1}{1.3\,s + 1}
\]
The reference is a unit step (1 m/s) speed command. For each controller
configuration below, predict the steady-state error analytically, then verify
with a short MATLAB script (`feedback`, `step`).

a. **P only**, $K_P = 0.5$
b. **PI**, $K_P = 0.5$, $K_I = 0.4$
c. **P + feedforward**, $K_P = 0.5$, $K_{ff} = 1/K_\mathrm{plant}$
d. **PI + feedforward**, same $K_P, K_I, K_{ff}$ as above

e. *(Coda)* Use the chapter's *adaptation argument* (not the SSE formula)
   to explain in one or two sentences why the PI controller in (b) drives
   the error to zero.

**Concepts:** Integrator increments Type; feedforward does *not* change
Type; PI + FF combination; integrator adaptation argument; MATLAB
verification (no `minreal` needed — `dcgain(feedback(...))` of the
closed-loop TF is enough).

### Problem 6 — *USV yaw: ramp tracking design*

The USV's yaw-heading dynamics (illustrative numbers):
\[
  G_r(s) = \frac{0.5}{s\,(0.8\,s + 1)}
\]
A proportional controller $C(s) = K_r$ is used in a unity-feedback loop. The
heading reference ramps at 5°/s (a constant turn rate).

a. What is the system Type of the closed loop? Justify in one phrase.
b. Find $K_v$ in terms of $K_r$, and compute the steady-state heading lag
   in degrees as a function of $K_r$.
c. The design spec is a heading lag $\le 1°$. Find the minimum $K_r$
   that meets it.
d. *(Coda)* Your collaborator says: "The plant already has a $1/s$ in it,
   so it's Type 1. Increasing $K_r$ makes it Type 2, which would give us
   zero ramp error." Critique this statement in one or two sentences.

**Concepts:** Ramp tracking on an inherently-Type-1 plant; $K_v$ design;
unit conversion (rad ↔ deg); the overloaded-notation point — proportional
gain doesn't add integrators.

---

## 4. Suggested final ordering

1. **Problem 1** — Type 0 baseline (warm-up)
2. **Problem 4** — Fill-the-table (cements the diagonal pattern)
3. **Problem 2** — Type 1 with transient bridge to week 4
4. **Problem 3** — Design for a spec
5. **Problem 5** — USV surge: predict P / PI / P+FF / PI+FF
6. **Problem 6** — USV yaw: ramp tracking design

Rationale: pure-formula warm-ups first, then the pattern-recognition table,
then a transient/SSE bridge, then design, then USV applications. Conceptual
codas accumulate across the set without ever being a standalone "essay
question".

---

## 5. Open questions for the next pass

- **Yaw plant numbers** — proposed $G_r(s) = 0.5/(s(0.8s+1))$ is illustrative.
  Worth picking values that are plausible for the actual USV, even if not
  measured? % CLAUDE: We developed two standard models for the USV based on combining all the student dats.  $G_{\mathrm{surge}} = \frac{5.1}{1.3 \, s +1}$ and $G_{\mathrm{yaw-rate}} = \frac{0.82}{0.61 \, s +1}$
- **Problem 5 part (d) — PI + FF** — students will probably get $e_{ss} = 0$
  for both (b), (c), (d). Is the differentiation worth keeping, or do we trim
  to just (a), (b), (c) to avoid redundancy? % CLAUDE: I'll get to this level of detail when we prototype in latex.
- **MATLAB scope** — Problem 5 calls for `feedback` and `step`. Is that the
  full extent of the MATLAB ask for this assignment, or do we want one of
  the earlier problems (P3?) to also have a "verify with MATLAB" step? % CLAUDE: In general we look at MATLAB as a really powerful calculator for feedback control, so any useful matlab is encouraged.
- **Problem 4 third plant ($G_c$ has $s^2$ in denominator → Type 2)** — gives
  the only finite parabola entry in the table. Worth keeping for the
  diagonal-pattern reveal, even though Type 2 systems are uncommon (per the
  chapter's caveat)? % CLAUDE: No
