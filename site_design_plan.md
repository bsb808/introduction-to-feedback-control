# Course-Site Design Plan

**Status:** draft for refinement
**Goal:** replace the decommissioning Confluence wiki with a GitHub-native course site, published from this public repo to GitHub Pages, that supports per-quarter remixes (home, syllabus, schedule, assignments) without duplicating content.

---

## 1. Tooling decision

- **Static site generator:** Quarto.
- **Hosting:** GitHub Pages on `bsb808/introduction-to-feedback-control`, served from the `gh-pages` branch. 
- **Build:** GitHub Actions on push to `main` runs `quarto render` and pushes the rendered HTML to `gh-pages`.

Why Quarto over the alternatives is captured in conversation; not repeated here. Decision is revisitable until the first quarter ships from it.

---

## 2. Repo layout

The site lives in a new top-level `site/` folder inside the public repo. `book/`, `matlab/`, `misc/`, and `utils/` are untouched.

```
introduction-to-feedback-control/
  book/                    # existing — LaTeX chapters + book.pdf
  matlab/                  # existing
  misc/                    # existing
  site/                    # NEW
    _quarto.yml            # site-wide config (theme, navbar, output dir)
    _variables.yml         # per-quarter values (quarter, term, dates)
    index.qmd              # landing page
    syllabus.qmd
    schedule.qmd           # rendered from data/schedule.yml
    assignments.qmd        # index of assignments
    weeks/
      w01_laplace_part1.qmd
      w02_laplace_part2_modeling.qmd
      ...                  # mirrors book/wXX_* folder names
    assignments/
      hw01.qmd
      ...
    includes/              # reusable snippets (office hours, integrity, sakai block)
    data/
      schedule.yml         # one row per class meeting / week
      assignments.yml      # due dates, weights, links
    assets/                # site-only static files (images, small PDFs)
  .github/
    workflows/
      publish-site.yml     # render + deploy to gh-pages
```

**Built artifacts (book.pdf, per-week chapter PDFs)** are not committed to `site/`. The publish workflow either (a) builds them in CI and copies into the site output, or (b) downloads them from a GitHub Release. See §7.

---

## 3. Public/private boundary

The umbrella has a `-private` sibling that mirrors the public structure. Site implications:

- **Authoritative answer keys, oral-exam questions, instructor notes** stay in the private repo. The public site never links to them.
- **Solution PDFs released after a deadline** can either (a) move into the public repo at release time, or (b) live in the private repo and get distributed to students directly. Default is (b) — keeps the public site stable.
- **No build-time secrets.** The Action only reads from the public repo. If a future need crosses that line we add a deploy key, not before.

---

## 4. Content architecture

### Page roles

| Page | Source of truth | Per-quarter changes |
|------|-----------------|---------------------|
| `index.qmd` | hand-edited | Welcome message, current-quarter banner |
| `syllabus.qmd` | hand-edited + `_variables.yml` | Term dates, meeting times, instructor info |
| `schedule.qmd` | rendered from `data/schedule.yml` | Calendar/index table — date, topic, link to week page, due items, week type (lab/lecture/holiday). Does **not** carry the rich week content. |
| `assignments.qmd` | rendered from `data/assignments.yml` | Due dates, links to assignment pages |
| `weeks/wXX_*.qmd` | hand-edited | **Per-quarter content owner.** Holds the day-by-day rich material currently embedded in wiki schedule cells: topic, video-lecture links (Vimeo / Sharepoint / OneDrive) with titles and durations, slides (annotated and not), handouts, "before class" / "due" sub-blocks, optional notes. Updated each quarter. |
| `assignments/hwNN.qmd` | hand-edited | Stable across quarters; due date pulled from data |

**Why per-week pages own content rather than the schedule:** the existing wiki packs the entire weekly rhythm (videos, slides, handouts, notes) into schedule cells. That is hard to author, hard to read on mobile, and forces the data file to carry rich nested content. Letting `weeks/wXX_*.qmd` own the content keeps the schedule scannable and lets each week's page evolve in plain Markdown.

### Reusable includes

No reusable includes anticipated at this stage. The `site/includes/` directory is reserved for snippets that emerge organically — add one only when the same paragraph would otherwise appear in two places. Academic-integrity boilerplate lives inside `syllabus.qmd`, not as an include. Sakai, contact, and office-hours blocks are not needed.

### Variables (`_variables.yml`)

```yaml
quarter: "Spring 2026"
term_start: "2026-04-06"
term_end:   "2026-06-12"
```

Used in pages as `{{< var quarter >}}`. One file to edit at the start of each term.

---

## 5. Per-quarter remix mechanism

**Recommended:** single-branch model with Git tags for historical snapshots.

- `main` always reflects the *current* quarter. Updating `_variables.yml`, `schedule.yml`, and `assignments.yml` is the per-quarter ritual.
- After a quarter ends, tag the commit: `git tag site-2026-spring && git push --tags`.
- To rebuild a past quarter's site, `git checkout site-2026-spring` and render locally — no need for it to be live.
- **Past quarters are not published simultaneously.** If we ever want them, switch to per-quarter subdirectories under `site/quarters/` later — that change is small and reversible.

Rejected alternatives:
- **Branch per quarter** — Pages serves one branch; juggling branches loses the live-edit-on-main flow.
- **Per-quarter subdirectories from day one** — overkill until there's a real need.

---

## 6. Schedule data shape

`site/data/schedule.yml` drives `schedule.qmd`. The data file is intentionally **slim** — it carries only what's needed to render the calendar/index table. Rich content (videos, slides, handouts, notes) lives on the per-week page and is reached via the `page` link.

Schema:

```yaml
- week: 1
  start_date: "2026-03-30"
  topic: "Course Introduction and Laplace Introduction"
  type: lecture          # lecture | lab | holiday | guest
  page: weeks/w01_laplace_part1.qmd
  due:
    - { what: "HW1",      when: "Friday 1700" }
    - { what: "Quiz #1",  when: "Before Mon class" }

- week: 3
  start_date: "2026-04-13"
  topic: "Lab 1 — USV System Identification"
  type: lab
  page: weeks/w03_usv_sysid.qmd

- week: 9
  start_date: "2026-05-25"
  topic: "Memorial Day (Mon) | Compensation Design (Wed)"
  type: holiday
```

`type` drives row coloring in the rendered table (yellow=lecture, blue=lab, grey=holiday/no-class) — preserves the wiki's color-coding semantics.

Per-day rhythm (Mon/Tue/Wed/Thu in-person vs. async) is **not** in the data file. It lives on the week page in whatever structure suits that week.

Gradual reveal: a `published: true|false` flag per week, or — simpler — a `reveal_after` date checked at render time. Defer until a real need.

---

## 7. Attachments and PDFs

Three classes of attachment, each handled differently:

| Type | Where it lives | How the site links to it |
|------|---------------|--------------------------|
| Per-week handouts, slides, MATLAB files (PDF / PPTX / MLX / M) | `site/assets/wXX/` mirroring the week structure | Relative link from the week page |
| Built chapter PDFs (`book/wXX_*/chapter.pdf`, `book.pdf`) | Not in `site/`; built by CI | Action copies into `_site/book/...` during render |
| Large or rarely-changing PDFs (legacy lecture videos that need rehosting, full textbook scans, etc.) | GitHub Release on the repo | Link to release asset URL |

The `book/` LaTeX build is already wired through `Makefile`. The publish workflow runs `make` before `quarto render` and copies built PDFs into the site output directory.

External links (papers, MathWorks docs, vendor sites, Vimeo / Sharepoint / OneDrive video hosting) stay as plain URLs — no caching or rehosting.

### Migrating attachments from the existing wiki

The current Confluence content references **30+ attachments per quarter** (lecture slides plus annotated versions, handouts, .mlx live scripts, .m scripts, .pptx). One-time migration before the wiki goes dark:

1. Inventory: enumerate attachment URLs across the wiki pages we're keeping.
2. Bulk download to `site/assets/wXX/` using a small script (Confluence supports REST attachment download with cookie-auth).
3. Rewrite links in the rebuilt `weeks/wXX_*.qmd` pages to the local relative paths.

Skip downloading attachments tied to pages we're dropping. After migration, the wiki can go dark without breaking the site.

---

## 8. Build and deploy

`.github/workflows/publish-site.yml`:

1. Checkout
2. Install TeX Live (for `book/` PDFs)
3. Install Quarto
4. `make -C book` to build chapter PDFs
5. Copy built PDFs into `site/_freeze/` or directly into the render output
6. `quarto render site/`
7. Deploy `site/_site/` to `gh-pages` via `peaceiris/actions-gh-pages` or `actions/deploy-pages`

Local preview during authoring: `cd site && quarto preview`. No CI needed for drafts.

---

## 9. Authoring workflow

**Routine edits (typo, schedule tweak, link update):**
1. Edit the `.qmd` or `.yml` file in VSCode
2. `quarto preview` running in the background hot-reloads
3. Commit and push — Action publishes within a couple minutes

**New week or assignment:**
1. Add a row to `data/schedule.yml` or `data/assignments.yml`
2. If it has a dedicated page, copy a sibling `.qmd` and edit
3. Same commit/push flow

**Start of a new quarter:**
1. Tag the previous quarter (`git tag site-2026-spring`)
2. Update `_variables.yml` (term, dates)
3. Update `schedule.yml` (dates, possibly topic order)
4. Refresh `assignments.yml` due dates
5. Skim `index.qmd` and `syllabus.qmd` for stale references (term, dates, links)
6. Push

The "start of quarter" should be a checklist file (`site/QUARTER_CHECKLIST.md`) that lives next to the data files.

---

## 10. Confluence as a model, not a migration target

The existing Confluence space is a reference for *what kinds of pages have proven useful* — not a thing to reproduce one-for-one. Expect the site to refactor structure and drop pages that were workarounds for wiki limitations rather than genuine course content.

Practical use of the old Confluence content:
- **Skim and inventory** — note which pages are actually load-bearing (linked from class artifacts, referenced in lectures). Drop the rest.
- **Salvage attachments worth keeping** — pull PDFs/images that aren't already in the repo.
- **Rebuild, don't import** — write the new pages fresh, using Confluence content as raw material when convenient.

No Confluence-URL redirect strategy is planned. External pointers (LMS, old syllabi) will be allowed to break; the new site URL becomes the authoritative one going forward.

---

## 11. Phased rollout

**Phase 1 — Skeleton (1 sitting).**
Stand up `site/` with `_quarto.yml`, `index.qmd`, `syllabus.qmd`, `schedule.qmd` (hard-coded table to start), the workflow, and Pages enabled. Publish a "coming soon" page.

**Phase 2a — Calendar-only schedule (1 sitting).**
Move the schedule into `data/schedule.yml` using the slim schema in §6. `schedule.qmd` renders the calendar table with topic, due items, and (initially dead) links to per-week pages. Add `_variables.yml`. Wire in the existing `book.pdf` as a download. No per-week pages exist yet.

**Phase 2b — One end-to-end week page.**
Pick one concrete week (suggest **Week 1**, since it's mostly settled and exercises video links + slides + handouts + due-items) and build the full `weeks/w01_*.qmd` page. Decide the per-week page format here, on a real week, before scaling. Resolve: how to lay out Mon/Tue/Wed/Thu rhythm; where attachments go; how to label optional vs. required content; how the page links back to the schedule.

**Phase 3 — Migrate remaining weeks (incremental).**
Apply the format chosen in 2b to each remaining week. Run the attachment download script (§7) once before this phase begins. Pages can land in any order — schedule already links to them.

**Phase 4 — Polish.**
Theme tweaks, search, custom landing-page hero, anything cosmetic.

Each phase ends with a working, deployed site. Nothing in this plan requires finishing Phase 4 to teach from Phase 2.

---

## 12. Open questions

Decided during first review:

- [x] **Custom domain** — yes, use a custom domain the user already owns. Specific domain name TBD; needs CNAME + DNS record once chosen.
- [x] **Search** — disabled. Set `search: false` in `_quarto.yml`.
- [x] **Math rendering** — MathJax (Quarto default). Handles more LaTeX corners than KaTeX; page-load is acceptable.
- [x] **Comments / discussion** — none on the site.
- [x] **Analytics** — none.
- [x] **PDF chapter strategy** — build in CI. Plan on TeX Live caching to keep build time tolerable.

Still open:

- [ ] **Past quarters live?** Default plan is "no, only the current quarter is published; past quarters live as Git tags." Override if there's a real need.
- [ ] **Schedule schema** — to be designed from a concrete example you provide (§6).
- [ ] **Custom domain name** — pick the actual hostname when ready to wire it up.

---

## 13. Risks

- **CI build time.** TeX Live + figure rendering can push past 5 minutes. Mitigate with cache actions and Quarto's `_freeze`.
- **Per-quarter ritual gets skipped.** If `_variables.yml` isn't updated, the syllabus shows last term. Mitigated by the QUARTER_CHECKLIST file and by surfacing the term name prominently on the home page so a stale value is visible.
- **Operating principle: keep web-native and PDF content separate.** The LaTeX book and the web site are two delivery channels with different ergonomics; we won't try to make them share source. Web pages are authored as `.qmd`; chapters stay as `.tex`. The site links to built chapter PDFs rather than re-rendering chapter content as HTML. This sidesteps LaTeX-to-qmd conversion drag entirely.

---

## Refinement notes

Decisions made during first review (2026-05-08):

- **No reusable-include set up front.** Office hours, contact, Sakai, academic-integrity boilerplate all dropped or absorbed into `syllabus.qmd`.
- **No Sakai integration on the site.** Students already know where Sakai lives; the site won't link in or surface course URLs.
- **No Confluence migration.** Existing Confluence is a reference, not a target — rebuild fresh, refactor freely, allow old URLs to break.
- **Web vs. PDF stay separate.** `.tex` chapters render to PDF; web pages are authored as `.qmd`. No shared source; no conversion pipeline.
- **Open questions resolved:** custom domain (yes, TBD which), search (off), math (MathJax), comments (none), analytics (none), PDF strategy (build in CI). See §12.

Still to resolve before scaffolding:

- Hostname for the custom domain.

Decisions made during second review (2026-05-08), after seeing wiki samples:

- **Per-week pages own rich content; schedule is a slim calendar/index.** §4 page roles updated: `weeks/wXX_*.qmd` is now the per-quarter content owner (videos, slides, handouts, daily rhythm). `schedule.qmd` becomes a scannable calendar that links to it.
- **Schedule schema defined** (§6). Slim YAML — week, start_date, topic, type, page link, due items. `type` (lecture/lab/holiday/guest) drives row coloring.
- **Attachment volume planned for** (§7). `site/assets/wXX/` mirrors the week structure; one-time Confluence download script before the wiki goes dark.
- **Phase 2 split into 2a/2b** (§11). Stand up the calendar first, then format-find on a single concrete week (suggest Week 1) before scaling to the remaining weeks.
