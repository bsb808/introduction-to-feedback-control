# Introduction to Feedback Control

Course materials for ME 2801 — Introduction to Feedback Control.

## Contents

Each `weekNN_<topic>/` directory contains:
- `chapter/` — LaTeX source for the chapter document
- `assignment/` — LaTeX source for the assignment (`assignment_<topic>.tex`)
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

## Claude Code session history

Session history for this repo is stored in the paired private repository
[introduction-to-feedback-control-claude](https://github.com/bsb808/introduction-to-feedback-control-claude).
The repo holds the `.jsonl` conversation logs and the `memory/` subdirectory
of persistent auto-memory (user preferences, project context, feedback that
Claude carries across sessions).

To restore sessions on a new machine:

```bash
# Clone both repos to the same parent directory
git clone git@github.com:bsb808/introduction-to-feedback-control.git ~/WorkingCopies/introduction-to-feedback-control
git clone git@github.com:bsb808/introduction-to-feedback-control-claude.git ~/WorkingCopies/introduction-to-feedback-control-claude

# Symlink the session repo into Claude Code's project directory
ln -s ~/WorkingCopies/introduction-to-feedback-control-claude \
      ~/.claude/projects/-home-bsb-WorkingCopies-introduction-to-feedback-control
```

To checkpoint your session history to GitHub:

```bash
cd ~/WorkingCopies/introduction-to-feedback-control-claude
git add -A && git commit -m "sync sessions" && git push
```

Or use `make sync-all` from this repo's root to push public, private, and
session history in one step.
