# Book-wide Conventions

Notation, naming, and diagram-style conventions used across all chapters.
These are the **defaults** — individual chapters occasionally violate them
where context demands, but new material should follow these unless there's a
specific reason not to.  Track known violations in `TODO.md`.

---

## Signal naming (frequency domain, capitalized)

| Symbol  | Meaning                                                |
|---------|--------------------------------------------------------|
| `R(s)`  | Command, setpoint, reference                           |
| `E(s)`  | Error,  `E = R − Y`                                    |
| `U(s)`  | Controller output (the actuating signal into the plant) |
| `Y(s)`  | Output, response                                       |

Time-domain equivalents are the same letters lowercase: `r(t)`, `e(t)`, `u(t)`,
`y(t)`.

---

## Transfer-function naming (frequency domain)

**Building blocks:**

| Symbol  | Meaning      |
|---------|--------------|
| `G(s)`  | Plant        |
| `C(s)`  | Controller   |
| `F(s)`  | Feedforward  |

**Composite (loop-level) TFs:**

| Symbol         | Meaning                                                    |
|----------------|------------------------------------------------------------|
| `G_{ol}(s)`    | Open-loop / forward-path / loop TF (e.g. `C(s) G(s)`)      |
| `G_{cl}(s)`    | Closed-loop / effective TF (`Y(s)/R(s)` after `feedback`)  |

**Known violation.**  The SSE chapter (`w06_steady_state_error/`) uses bare
`G(s)` for the combined forward-path TF, not the plant — should be `G_{ol}(s)`.
Flagged in `TODO.md`.

### MATLAB variable naming

Mirrors the math symbols (LaTeX subscripts → flat names):

| Variable  | Math equivalent | Meaning                          |
|-----------|-----------------|----------------------------------|
| `G`       | `G(s)`          | Plant                            |
| `C`       | `C(s)`          | Controller                       |
| `F`       | `F(s)`          | Feedforward                      |
| `Gol`     | `G_{ol}(s)`     | Open-loop / forward-path TF      |
| `Gcl`     | `G_{cl}(s)`     | Closed-loop TF (after `feedback`)|

Suffixes for derived TFs use underscores: `Gcl_ramp = Gcl * tf(1,[1 0])`.

---

## Block-diagram style (TikZ)

Standalone TikZ diagrams live in `book/wXX_topic/tikz/`, one diagram per
`.tex` file.  Each file is fully self-contained (no shared preamble) — copy
from `book/w06_steady_state_error/tikz/closed_loop.tex` as the seed for new
diagrams.

### Common style block

```latex
\documentclass[border=4pt]{standalone}
\usepackage{tikz}
\usetikzlibrary{positioning, calc, arrows.meta}

\begin{tikzpicture}[
  >={Latex[length=1.5mm, width=1.2mm]}, thick,
  block/.style = {draw, rectangle, minimum height=2.5em, minimum width=4.5em},
  sum/.style   = {draw, circle, inner sep=0pt, minimum size=1.2em},
]
  ...
\end{tikzpicture}
```

### Conventions inside the picture

- **Blocks** carry the math symbol of the TF: `{$C(s)$}`, `{$G(s)$}`.
- **Summing junctions** are empty circles; polarity is shown by small `$+$` /
  `$-$` text nodes anchored at the corner of the circle:
  ```latex
  \node[font=\scriptsize, inner sep=0pt, anchor=south east]
    at (sum.north west) {$+$};
  \node[font=\scriptsize, inner sep=0pt, anchor=north east]
    at (sum.south west) {$-$};
  ```
- **Branch points** are 2pt filled black circles at the tap location:
  `\fill (rbranch) circle (2pt);`
- **Signal arrows** carry their math symbol as the edge label:
  `\draw[->] (sum) -- node[above]{$E(s)$} (C);`
- **Inter-block horizontal spacing**: 1.4–1.6 cm typical.
- **Feedback path** drops 1.4 cm below the main row, then routes orthogonally
  back to the sum:
  `\draw[->] (fbk) -- ++(0,-1.4) -| (sum.south);`

---

## Build & export

- **Build a diagram**: `pdflatex foo.tex`  →  `foo.pdf` (vector, paste-ready).
- **PNG for non-PDF targets**: `pdftocairo -png -r 300 foo.pdf foo`.
- **SVG for web**: `pdftocairo -svg foo.pdf foo.svg`.
- **Inclusion in book chapters**: `\includegraphics{tikz/foo.pdf}`.

---

## Open items (resolve as they come up)

- [ ] Disturbance signal: symbol and where it injects in the canonical diagram.
- [ ] Sensor noise: symbol and injection point.
- [ ] Sensor / feedback-path TF symbol when feedback is non-unity.
- [ ] Bode-plot style conventions (line widths, axis labels — partially
      established in `matlab/sketchbode.m`; document here).
- [ ] Step / ramp / parabola input naming in plots (currently mixed).
