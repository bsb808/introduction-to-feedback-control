# Introduction to Feedback Control

Course materials for ME 2801 — Introduction to Feedback Control.

## Contents

Each `wNN_<topic>/` directory under `book/` contains:
- `chapter/` — LaTeX source for the chapter document
- `assign/` — LaTeX source for the assignment
- `code/` — MATLAB companion scripts
- `refs/` — reference materials

Reusable MATLAB utilities (Bode sketching, etc.) are in `matlab/`.
USV lab pipeline scripts are in `utils/ardu_utils/`.

## Building LaTeX documents

```bash
pdflatex <file>.tex
# or for full cross-reference resolution:
latexmk -pdf <file>.tex
```

Required LaTeX packages (Ubuntu/Debian):

```bash
sudo apt install -y \
    texlive-latex-extra \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-science \
    texlive-plain-generic
```

## Three-repo layout

This repo is one of three siblings cloned under an umbrella directory of your choice:

```
<umbrella>/                                      # e.g. ~/WorkingCopies/me2801/
  introduction-to-feedback-control/              # public — this repo
  introduction-to-feedback-control-private/      # instructor-only notes
  introduction-to-feedback-control-claude/       # Claude Code session logs + memory
```

Claude Code is launched from `<umbrella>/`, not from this repo. That makes all three repos reachable as siblings, and lets the `-claude` repo back its session/memory directory (which Claude Code locates by encoding the umbrella's absolute path).

### Setup on a new machine

```bash
# 1. Pick an umbrella dir name and clone all three repos into it
UMBRELLA=~/WorkingCopies/me2801
mkdir -p "$UMBRELLA" && cd "$UMBRELLA"
git clone git@github.com:bsb808/introduction-to-feedback-control.git
git clone git@github.com:bsb808/introduction-to-feedback-control-private.git
git clone git@github.com:bsb808/introduction-to-feedback-control-claude.git

# 2. Replace Claude's auto-created project dir with a symlink into the -claude repo
cd introduction-to-feedback-control
make link-claude

# 3. Verify
make doctor
```

`make link-claude` derives the slug `~/.claude/projects/<umbrella-path-with-/-as->/` from the current umbrella path, so it works regardless of OS, username, or umbrella name.

### Day-to-day git ops

From inside the public repo:

| Command | Effect |
|---------|--------|
| `make status-all` | git status of public, private, and claude |
| `make pull-all`   | git pull on all three |
| `make push-all`   | git push on all three (auto-commits session sync in `-claude`) |
| `make sync-all`   | pull then push on all three |
| `make doctor`     | sanity-check layout invariants on this machine |
