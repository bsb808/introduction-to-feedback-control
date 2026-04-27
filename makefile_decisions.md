# Makefile design — decisions needed

Reply inline under each question. (BSB: replies go below; CC: my responses below yours.)

## Survey of the repo

- Each `week*/chapter/*.tex` is a standalone `\documentclass{article}`.
  - BSB: Can we reorganize so we can build them standalone or as chapters in a book? Commit before reorg?
  - CC: Yes — `subfiles` package supports exactly this. Plan in §1 below. Agreed on commit-first.
- Week 07 and Week 10 have empty `chapter/` directories.
  - BSB: Add placeholder latex docs.
  - CC: Will add `chapter/usv_pid.tex` and `chapter/usv_nav.tex` placeholders matching the new format.
- Handout-style `.tex` in `week*/refs/`.
  - BSB: Leave out of building.
  - CC: Excluded from all targets.
- Top-level `latex/` empty.
  - BSB: Delete it.
  - CC: Will delete. Master `book.tex` needs a new home — see §1a.

---

## 1. Refactor plan ("standalone OR in a book")

### Approach: `subfiles` package
Each chapter file becomes a `subfiles` document. When run standalone, the subfile inherits the master preamble and produces a self-contained PDF. When the master is built, it `\subfile{...}`s each chapter into a `book` document.

### Preamble survey (across the 8 existing chapters)
- **7 of 8** share an essentially identical preamble: `geometry`, `amsmath`, `amssymb`, `graphicx`, `booktabs`, `hyperref`, `cleveref`, `microtype`, `parskip` (+ `fancyvrb` in most).
- **week05, week06** additionally use `tikz` + libraries.
- **week04, week08, week09** add `\graphicspath{...}` (varies).
- **week03 (USV sysid lab)** is the outlier: uses `times`, `pdfpages`, `fullpage`, `fancyhdr`, `mathpazo`, `enumitem`, `tabularx`, `multirow`, etc. Lab-handout aesthetic.
- `\figplaceholder` is defined identically in 7 of 8 chapters.

### What changes per chapter (typical, e.g. week01)

**Before** (~24 lines):
```latex
\documentclass[12pt]{article}
\usepackage[margin=1in]{geometry}
... (10 \usepackage lines) ...
\newcommand{\figplaceholder}{...}
\title{Laplace Transforms: ...}
\author{}
\date{}
\begin{document}
\maketitle
\tableofcontents
\newpage
% ...body...
\end{document}
```

**After** (~6 lines around the body):
```latex
\documentclass[../../book/book.tex]{subfiles}
\begin{document}
\chaptertitle{Laplace Transforms: The Mathematical Foundation}{1}
% ...body unchanged...
\end{document}
```

`\chaptertitle{title}{week-number}` is a macro defined in the master that:
- in standalone mode: emits `\title{...}\maketitle\tableofcontents\newpage`
- in book mode: emits `\chapter{...}` (no per-chapter TOC)

### Master file `book/book.tex` (new top-level `book/` dir, since `latex/` is being deleted)
Holds the union of all packages, the `\figplaceholder` definition, `\graphicspath` for the image dirs, and `\subfile{...}` calls for each chapter in week order.

### Disturbance assessment
- **Touched files:** 8 existing chapter `.tex` files + 2 new placeholders (week07, week10).
- **Per file:** ~20 preamble lines deleted, replaced with 1-line `\documentclass{subfiles}` wrapper; title block (3-4 lines) replaced with one `\chaptertitle{...}{...}` call. **Body content untouched.**
- **New files:** `book/book.tex`, `book/me2801.sty` (shared preamble; or inline in book.tex).
- **Outlier — week03 USV sysid:** the lab handout uses very different styling (fancyhdr, mathpazo, pdfpages). Three options:
  - (a) Hoist its packages into the master preamble (mostly compatible; `mathpazo` would change book-wide font — likely undesirable).
  - (b) Keep week03 standalone-only, exclude it from `book.tex` (book skips lab weeks).
  - (c) Strip week03's special styling so it matches the rest.

  **CC recommendation: (b)** — lab handouts are a different document genre from textbook chapters. Same applies to week07 and week10 if they're lab handouts.

 BSB: Let's try (c).  Even if the tone of the "book" is different for this chapter (and the two other lab chapters), that is fine.  Since this is CC co-authored, it can be specific to our use case. 

- **Risk areas:**
  - `\graphicspath` resolution differs between standalone and book builds — `subfiles` v2.x handles this if relative paths are written as if from the subfile dir.
  - Per-chapter `tikz` libraries (week05/06) need to be in master, so all chapters compile with tikz loaded (harmless).
  - `cleveref` references across chapters: only meaningful in book mode; standalone refs only resolve within the chapter (already true today).

### Open sub-questions for the refactor

**1a. Where does `book.tex` live?** Top-level `book/` directory? Or just at repo root?
- BSB:  Let's move all the weeks into a "book" top-level directory.

**1b. Lab weeks (03, 07, 10) — include in book or keep standalone-only?**
- BSB: Integrate into book

**1c. Book title / author / cover page?**
- BSB: Introduction to Feedback Control, Brian Bigham.

**1d. Standalone chapter PDFs — should they keep `\title{...}\maketitle\tableofcontents` like today, or switch to a simpler `\section*{Title}` (no TOC)?**
- BSB:  Let's keep TOC for each chapter for now.  I'm doing htis one chapter at a time, then later goin gto build it into a single book.

---

## 2. Per-week argument syntax
- (a) `make week NAME=week01_laplace_part1`
- (b) `make week01_laplace_part1` — the target name *is* the week directory
- (c) Short form like `make w01`

BSB: (c)

---

## 3. Output location
- (a) PDFs alongside the `.tex` source
- (b) All collected into a top-level `build/`
- (c) Into `book/build/`

BSB: (a)

---

## 4. Build tool
- (a) `latexmk -pdf` (recommended)
- (b) Plain `pdflatex`

BSB: a

---

## 5. Empty chapters (week 07, 10) → placeholders
Confirm content of placeholder: just `\chaptertitle{...}{N}` + a single sentence "Content forthcoming"?

BSB: yes
