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
    _variables.yml         # per-quarter values (quarter, term, dates, sakai links)
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
- **Solution PDFs released after a deadline** can either (a) move into the public repo at release time, or (b) live in the private repo and get distributed via Sakai. Default is (b) — keeps the public site stable.
- **No build-time secrets.** The Action only reads from the public repo. If a future need crosses that line we add a deploy key, not before.

---

## 4. Content architecture

### Page roles

| Page | Source of truth | Per-quarter changes |
|------|-----------------|---------------------|
| `index.qmd` | hand-edited | Welcome message, current-quarter banner |
| `syllabus.qmd` | hand-edited + `_variables.yml` | Term dates, meeting times, instructor info |
| `schedule.qmd` | rendered from `data/schedule.yml` | Dates, topics, assigned reading, due items |
| `assignments.qmd` | rendered from `data/assignments.yml` | Due dates, links to assignment pages |
| `weeks/wXX_*.qmd` | hand-edited | Stable across quarters; small per-quarter notes via includes |
| `assignments/hwNN.qmd` | hand-edited | Stable across quarters; due date pulled from data |

### Reusable includes

Snippets in `site/includes/` are pulled into pages with `{{< include >}}`:

- `_office_hours.qmd` — current term's hours (one place to edit) % CLAUDE: Not needed - I don't do office hours
- `_sakai_links.qmd` — Sakai gradebook, submission portal, quizzes (one place to edit)  % CLAUDE: No need to integrate with sakai.  Students know were the sakai site is and what is there.
- `_academic_integrity.qmd` — boilerplate that rarely changes % CLAUDE: This boilerplate will be folded into the syllabus
- `_contact.qmd` — instructor contact block % CLAUDE: Not really needed.  They know how to find me.

### Variables (`_variables.yml`)

```yaml
quarter: "Spring 2026"
term_start: "2026-04-06"
term_end:   "2026-06-12"
sakai_course_url: "https://sakai.example.edu/portal/site/..."
gradebook_url:    "..."
```

Used in pages as `{{< var quarter >}}`. One file to edit at the start of each term.

---

## 5. Per-quarter remix mechanism

**Recommended:** single-branch model with Git tags for historical snapshots.  % CLAUDE: Approved

- `main` always reflects the *current* quarter. Updating `_variables.yml`, `schedule.yml`, and `assignments.yml` is the per-quarter ritual.
- After a quarter ends, tag the commit: `git tag site-2026-spring && git push --tags`.
- To rebuild a past quarter's site, `git checkout site-2026-spring` and render locally — no need for it to be live.
- **Past quarters are not published simultaneously.** If we ever want them, switch to per-quarter subdirectories under `site/quarters/` later — that change is small and reversible.

Rejected alternatives:
- **Branch per quarter** — Pages serves one branch; juggling branches loses the live-edit-on-main flow.
- **Per-quarter subdirectories from day one** — overkill until there's a real need.

---

## 6. Schedule data shape

`site/data/schedule.yml` drives both `schedule.qmd` and any "this week" widgets. % CLAUDE: Let's discuss the schedule separately.  I can show you an example.

```yaml
- week: 1
  date: 2026-04-06
  topic: "Laplace transforms, part 1"
  reading:
    - { label: "Book §1", file: "book/w01_laplace_part1/chapter.pdf" }
    - { label: "Notes",    url: "..." }
  assigned:
    - hw01
  due: []
  draft_after: 2026-04-06   # hides links to material before this date
```

Quarto template walks the list and emits a table. `draft_after` lets the whole quarter be edited in advance and revealed week-by-week.

---

## 7. Attachments and PDFs

Three classes of attachment, each handled differently:

| Type | Where it lives | How the site links to it |
|------|---------------|--------------------------|
| Small static PDFs (1-pagers, handouts) | `site/assets/` in the repo | Direct relative link |
| Built chapter PDFs (`book/wXX_*/chapter.pdf`, `book.pdf`) | Not in `site/`; built by CI | Action copies into `_site/book/...` during render |
| Large or rarely-changing PDFs | GitHub Release on the repo | Link to release asset URL |

The `book/` LaTeX build is already wired through `Makefile`. The publish workflow runs `make` before `quarto render` and copies built PDFs into the site output directory.

External links (papers, MathWorks docs, vendor sites) stay as plain URLs — no caching or rehosting.

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
2. Update `_variables.yml` (term, dates, Sakai URLs)
3. Update `schedule.yml` (dates, possibly topic order)
4. Refresh `assignments.yml` due dates
5. Skim `index.qmd` and `syllabus.qmd` for stale references
6. Push

The "start of quarter" should be a checklist file (`site/QUARTER_CHECKLIST.md`) that lives next to the data files.

---

## 10. Migration from Confluence  % CLAUDE: We can use the existing Confluence content as a model, but don't need to reproduce it.  Fine to refactor as we change tooling. 

Order of operations, approximately:

1. **Inventory** — list every Confluence page that's currently linked from any class artifact. Mark each as: keep / archive / drop.
2. **Export attachments** — Confluence's space export gives an HTML+attachment bundle. Extract just the PDFs/images we want to preserve and drop them in `site/assets/` or a release. 
3. **Convert pages** — for each "keep" page, convert to `.qmd`. Confluence-to-markdown converters exist but the output usually needs cleanup; for a small page count, hand-conversion is faster.
4. **Redirect strategy** — if old Confluence URLs are linked from external places (LMS, syllabi PDFs, emails), capture the old URL → new URL mapping in a `redirects.yml` and let the host (Pages doesn't do redirects natively, so use a meta-refresh stub page or document the mapping for users).

Confluence decommission timeline determines how aggressive step 4 needs to be.

---

## 11. Sakai handoff

Sakai stays the system of record for: submissions, gradebook, online quizzes, anything that needs auth.

The site links **into** Sakai via the `_sakai_links.qmd` include and the `sakai_course_url` variable. No content duplication. When Sakai URLs change quarter-to-quarter, they update in `_variables.yml` and propagate everywhere through the include.

---

## 12. Phased rollout

**Phase 1 — Skeleton (1 sitting).**
Stand up `site/` with `_quarto.yml`, `index.qmd`, `syllabus.qmd`, `schedule.qmd` (hard-coded table to start), the workflow, and Pages enabled. Publish a "coming soon" page.

**Phase 2 — Data-driven (1 sitting).**
Move the schedule into `data/schedule.yml`. Add `_variables.yml` and the includes pattern. Wire in the existing `book.pdf` as a download.

**Phase 3 — Migrate Confluence (incremental).**
Move the highest-traffic Confluence pages first. Per-week pages can be empty stubs that link to the chapter PDF until there's reason to flesh them out.

**Phase 4 — Polish.**
Theme tweaks, search, custom landing-page hero, anything cosmetic.

Each phase ends with a working, deployed site. Nothing in this plan requires finishing Phase 4 to teach from Phase 2.

---

## 13. Open questions

These need answers before scaffolding (or are flagged as TBD-on-first-encounter):

- [ ] **Custom domain?** `bsb808.github.io/introduction-to-feedback-control/` works out of the box. A custom domain (e.g., `me2801.bsb808.dev`) needs a CNAME and a DNS record.  % CLAUDE: I aldready have a domain we can use. 
- [ ] **Search.** Quarto's built-in search is adequate; Algolia is overkill. Confirm.  % CLAUDE: No search needed. 
- [ ] **Math rendering.** MathJax (default) vs. KaTeX. MathJax handles more LaTeX corners; KaTeX is faster. Default to MathJax unless page-load matters. % CLAUDE: approved
- [ ] **Comments / discussion?** Probably no — Sakai handles class discussion. Confirm. % CLAUDE: confirmed
- [ ] **Analytics?** None by default. If desired, Cloudflare Web Analytics is privacy-friendly. % CLAUDE: none needed
- [ ] **Past quarters live?** Default plan is "no, only the current quarter is published; past quarters live as Git tags." Override if there's a real need.
- [ ] **PDF chapter strategy.** Build in CI vs. release vs. commit. Default is "build in CI." Confirm the CI build time is acceptable (TeX Live install is the slow part — caching helps). % CLAUDE: confirmed

---

## 14. Risks

- **CI build time.** TeX Live + figure rendering can push past 5 minutes. Mitigate with cache actions and Quarto's `_freeze`.
- **Per-quarter ritual gets skipped.** If `_variables.yml` isn't updated, Sakai links go stale and the syllabus shows last term. Mitigated by the QUARTER_CHECKLIST file and by surfacing the term name prominently on the home page so a stale value is visible.
- **LaTeX-to-qmd migration drag.** Avoid this by *not* migrating chapters until there's a reason. Weeks pages link to PDFs from day one; convert only the ones that benefit from being web-native (e.g., interactive plots, embedded videos).  % CLAUDE:  We can keep the web-native and PDF bits fairly separate.

---

## Refinement notes

Use this section to capture decisions and questions as the plan firms up.

- _(empty — to fill during review)_
