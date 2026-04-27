# Review Workflow

A git-diff-based process for reviewing and refining chapter/assignment drafts collaboratively with Claude.

## Overview

Reviews happen in two passes:

1. **Text edits** — you edit the file directly; Claude reviews your changes and proposes improvements
2. **`% CLAUDE:` comments** — inline action requests that Claude resolves one at a time

Each pass uses the same pattern: commit a baseline, apply proposed changes, open a diff editor to accept/reject/modify.

---

## Adding Review Comments

In any `.tex` or `.m` file, add inline comments anywhere you want Claude to take action:

```latex
\frac{dc}{dt} + 2c(t) = r(t), \qquad c(0) = 0 % CLAUDE: remove the IC from the equation
```

You can also edit text directly — Claude will notice and review those changes in pass 1.

---

## Pass 1: Reviewing Your Text Edits

1. Edit the file however you like (rewrite sentences, restructure, etc.)
2. Tell Claude: *"review my text edits"*
3. Claude:
   - Commits your current file as the baseline
   - Applies proposed improvements to your edits (spelling, tightening, style consistency)
   - Opens the diff editor
4. Review in VSCode diff editor; accept/reject/modify as needed
5. Tell Claude: *"I resolved the diff"*
6. Claude commits the result

---

## Pass 2: Resolving `% CLAUDE:` Comments

1. Tell Claude: *"process the CLAUDE comments"*
2. Claude scans the file and lists all comments, **numbered**
3. For each comment, Claude:
   - Commits the current file as the baseline
   - Applies the proposed resolution
   - Opens the diff editor
4. Review; accept/reject/modify
5. Tell Claude the comment number and status: *"resolved"* or *"skip #2, discuss"*
6. Claude commits and moves to the next comment

---

## Opening the Diff Editor

```bash
git show HEAD:path/to/file.tex > /tmp/file_HEAD.tex
code --diff /tmp/file_HEAD.tex path/to/file.tex
```

- **Left side** — committed baseline (read-only)
- **Right side** — proposed changes (editable)

The `.tex` extension on the temp file is required — without it VSCode can't identify the file type and shows a binary warning.

---

## Diff Editor Controls

Hover over a changed hunk in the right-hand pane to reveal gutter icons:

| Action | Effect |
|--------|--------|
| Accept Incoming | Keep the right side (proposed change) |
| Accept Current | Keep the left side (baseline) |
| Accept Both | Keep both versions stacked |

Controls are mouse-driven in the gutter (left edge of the line numbers). No default keyboard shortcuts — add them via `keybindings-help` if desired.

---

## Committing After Review

Claude commits each resolved state with a short message. If you want to push at the end of a session:

```bash
git push
```

---

## Quick Reference

| You say | Claude does |
|---------|-------------|
| "review my text edits" | Commits baseline, proposes improvements, opens diff |
| "process the CLAUDE comments" | Numbers all comments, resolves one at a time with diff |
| "I resolved the diff" | Commits the accepted result, moves on |
| "skip #N, discuss" | Leaves comment #N in place, opens chat |
| "yes" (to a typo/fix) | Applies the fix immediately, no diff needed |
