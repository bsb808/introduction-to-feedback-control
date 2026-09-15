# Spec: Wiki transition (one-time)

Companion to [spec_startup_new_quarter.md](spec_startup_new_quarter.md), which holds the recurring quarter runbook. This spec covers only the one-time move of course content from the NPS Confluence wiki to the Quarto site. It follows the same working loop (tasks with Objective, Inputs, Outputs, Owner, Verification, Status; PMR review gate; spec updated in the same commit as the work).

This spec supersedes §10 of [site_design_plan.md](../site_design_plan.md) (no Confluence migration).

A significant change from previous work is we are going to transfer the course content from the NPS wiki to the site pages here: [site/](../site/)

Because the Atlassian wiki is hard to access from Claude, the space was exported to `tmp/wiki/` (gitignored):

- `tmp/wiki/ME2801-150926-1018-12.pdf` — PDF export (133 pages; text and link URLs recoverable)
- `tmp/wiki/html/ME2801/` — HTML export (6.2 GB). 60 page files (~2.7 MB total) plus ~4,300 attachments under `attachments/<pageId>/<attachId>.<ext>`

Objective: transition the content from the wiki to this site, cleaning up the content as we go.

- Don't move over any archival information; only take what was necessary for the last version of the class (Spring quarter 2026, AY26Q3).
- Overall structure can stay similar. Small incremental improvements, but keep the site organization roughly the same.

Decisions:

- Restricted material (Nise textbook solutions, HW solutions, Nise textbook-table handout, exam schedule spreadsheet) does not go on the public site. It goes to Sakai only; the instructor copy lives in the private repo. Public pages say "Solutions posted on Sakai."
- Attachments are grouped by topic week (not by quarter), so current and archived pages link the same files. Exact placement is proposed in the inventory (open item 1).

Context-window management (the export is large):

- Never read raw wiki HTML or list `attachments/` unbounded. Use the extractor, which writes a compact Markdown extract and a link inventory per page to `tmp/wiki/extract/`.
- Copy attachments only from an approved manifest.

## 1. Extractor tooling

- Objective: turn a wiki page into a compact Markdown extract plus a link inventory, and copy approved attachments.
- Inputs: `tmp/wiki/html/ME2801/<page>.html`
- Outputs: [utils/wiki_migrate/extract.py](../utils/wiki_migrate/extract.py); `tmp/wiki/extract/<slug>.md`, `<slug>.links.tsv`
- Owner: AI
- Verification: spot-check the Schedule (26-3) extract against PDF export pages 5–9.
- Status: done
- Notes:
  - `./extract.py extract --all` writes all 60 pages (~1 MB total). The large 26-3 schedule becomes a 13 KB extract.
  - The HTML stores attachments by id; links that point at another page's attachments (`wiki.nps.edu/download/attachments/<page>/<name>`) are resolved to the local file through the `data-linked-resource-default-alias` attributes on all pages.
  - SharePoint `nav=` parameters are stripped in the Markdown (kept in the TSV).
  - The `restricted` column is a filename pattern safety net only; solutions are identified by where they appear (the Solutions column), not by name.

## 2. Transition inventory

- Objective: decide what transitions and what does not, before anything moves.
- Inputs: task 1 extracts
- Outputs: [specs/wiki_transition_inventory.md](wiki_transition_inventory.md) — one row per wiki page (disposition, target), and per kept page the attachment list with disposition.
- Owner: AI proposes, author reviews
- Verification: author review (PMR) before any migration.
- Status: review

## 3. Migrate pages

- Objective: rebuild kept pages as `.qmd`, cleaning as we go.
- Groups (one PMR each): (1) syllabus; (2) archived Spring 2026 schedule and assignments under `site/archive/ay26q3/` with attachments (these become the "previous quarter" archive pages that the quarter runbook's schedule and assignments tasks start from); (3) resources pages.
- Owner: AI
- Verification: `quarto render` clean; no `wiki.nps.edu` links in `site/`; no restricted files in `site/`; author checks content manually in `quarto preview`.
- Status: todo
