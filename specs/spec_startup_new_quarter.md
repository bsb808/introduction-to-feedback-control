# Spec: Tooling and process for setting up a new quarter

This is a regular and recurring task where we need to do a number of things to set up a new quarter. We will co-evolve this spec with any tooling and utilities development (spec-anchored: the spec is the source of truth; every decision or lesson learned during execution is written back here in the same commit as the work).

This spec supersedes the conflicting parts of [site_design_plan.md](../site_design_plan.md): §5 (past quarters as git tags only) and §6 (the `data/schedule.yml` rendering, which was never built). The one-time wiki migration has its own spec: [spec_wiki_transition.md](spec_wiki_transition.md).

## How we work

Each task below has Objective, Inputs, Outputs, Owner, Verification, and Status. For each AI-owned task:

1. Claude executes the task and produces the outputs.
2. Review gate using the PMR workflow: baseline commit, proposal applied, `code --diff`, author resolves.
3. Before the "resolved" commit, Claude updates this spec: Status, decisions, and anything next quarter should reuse.
4. Nothing is pushed without the author asking.

Status values: `todo`, `in progress`, `review`, `done`, `deferred`.

---

# Runbook

These are the tasks currently on the radar. We'll keep this list up to date as we execute.

Background:

- The class is taught fall and spring quarters.
- NPS academic calendars: https://nps.edu/web/registrar/calendar (download the AY PDF into `tmp/calendar/`). The key dates are the first day of classes, the last day of classes, holidays, and shift days. Finals can be ignored (typically nothing scheduled for finals week).
- Each quarter has constraints unique to that quarter that we need to schedule around (e.g., instructor travel). These are supplied by the author and recorded in the quarter log below.

## 1. Update syllabus in place

- Objective: update the syllabus with the new course days of the week, times, and room.
- Inputs: meeting days/times/room (supplied by author)
- Outputs: [site/syllabus.qmd](../site/syllabus.qmd); [site/_variables.yml](../site/_variables.yml) (`quarter`, `term_start`, `term_end`)
- Owner: AI, author review
- Verification: PMR; skim `index.qmd` and `syllabus.qmd` for stale references (term, dates, links, office hours).
- Status: todo

## 2. Start new schedule

- Objective: new schedule page for the quarter. At the start of the quarter it holds a complete overview table (dates, topic, due items, holiday and shift-day notes) and full details for the first two weeks; the remaining weeks are placeholders (see task 2a).
- Inputs: previous offering of the same season as a template (Fall or Spring); NPS calendar key dates; quarter constraints.
- Outputs: [site/schedule.qmd](../site/schedule.qmd) for the new quarter; previous schedule kept under `site/archive/<quarter>/schedule.qmd` with a note at the top saying it is archived and just for reference.
- Owner: AI initiates with constraints, author review
- Verification: every date in the grid checked against the weekday and the NPS calendar; PMR.
- Status: done (AY27Q1)
- Notes:
  - Page layout: overview table (Week, Starts, Topic, Due) with a symbol per holiday or shift day and a note under the table saying which class days are affected; then one section per week.
  - Placeholder week sections carry a "Details will be posted by <Monday two weeks before>" note, the holiday and shift-day impacts, and the week's due items.
  - The draft is made by copying the archived previous-quarter page, removing the `../../` link prefixes, and replacing week dates and quarter-specific items (holidays, guest lectures, end-of-term events).
  - Date check: a short Python check confirms every week row and heading is a Monday exactly N−1 weeks after instruction begins, and that each key date's weekday matches the NPS calendar and appears on the page. Candidate for a small committed script if it gets reused next quarter.

## 2a. Post week details (rolling, during the quarter)

- Objective: stay at least 1–2 weeks ahead of the calendar by replacing one placeholder week at a time with full details.
- Trigger: author says "post week N".
- Inputs: the archived previous-quarter schedule (baseline), the week mapping in the quarter log, the overview table's due items, and any notes for that week in the quarter log.
- Steps: copy the mapped section(s) from the archive; fix `../../` link prefixes; update dates, due items, holiday and shift-day notes; apply the week's notes; open the diff for the author to tune.
- Outputs: updated week section in [site/schedule.qmd](../site/schedule.qmd); the Due column and the week section must agree.
- Owner: AI drafts, author tunes and resolves
- Verification: PMR; week dates checked; `quarto render` clean.
- Status: weeks 1–2 posted; weeks 4–11 to post.

## 3. Assignments and labs

- Objective: start a new assignments page based on the most recent one. The new page has the layout, but only the first couple of assignments; the rest are posted as the quarter progresses.
- Outputs: [site/assignments.qmd](../site/assignments.qmd); previous page kept under `site/archive/<quarter>/assignments.qmd`, noted as archived.
- Update all links (navbar, `index.qmd`, `schedule.qmd`) so they point to the new assignments and labs page.
- Owner: AI, author review
- Verification: grep for links to the archived page from current pages returns nothing; PMR.
- Status: todo

## 4. Class info (human tasks)

- [ ] Verify class meeting days, times, and room in Python; add the class meetings to Outlook.
- [ ] Pull roster from Python, put copy in OneDrive.
- [ ] Request new Sakai site.
- [ ] Upload the Nise solutions manual to Sakai; update the Sakai link on the home page.

## 5. Publish

- [ ] Optional: tag the end of the previous quarter: `git tag site-YYYY-season && git push --tags`
- [ ] Skim `site/weeks/wXX_*/` pages for stale per-quarter content (dates, video links, leaderboards)
- [ ] Local preview: `cd site && quarto preview`
- [ ] Push and verify the published site after the GitHub Action runs.

---

# Quarter log

## AY27Q1 — Fall 2026

Key dates (from `tmp/calendar/2027 NPS Academic Calendar - Rev Aug2026.pdf`):

| Date | Event |
|---|---|
| Mon 28 Sep 2026 | Instruction begins |
| Mon 12 Oct | Columbus Day (holiday) |
| Tue 20 Oct | Shift day: treat as Friday class schedule |
| Wed 11 Nov | Veterans Day (holiday) |
| Thu 26 Nov | Thanksgiving (holiday) |
| Tue 8 Dec | Pre-graduation awards ceremony |
| Fri 11 Dec | Last day of classes |

Constraints:

- No class the week of 12–16 October (instructor travel). First schedule draft keeps that week in place; the author then refactors for the lost days.
- This fall is a bit different because of the new USV labs: merge the most recent offering (Spring 2026) with the USV lab schedule. Lab placement is decided at the schedule step (task 2).

Decisions:

- `_variables.yml` set to Fall 2026 (`term_start` 2026-09-28, `term_end` 2026-12-11). `meeting` still holds the Spring value until the author confirms times in Python.
- Week layout chosen by the author: Lab 1 moves to week 4 after the cancelled week; block diagrams and steady-state error share week 6. Homework renumbered HW1–HW5 (no separate steady-state-error homework); reading quizzes 1–4.
- Week mapping (Fall 2026 ← archived Spring 2026, `site/archive/ay26q3/schedule.qmd`):

  | Fall week | Topic | Spring source |
  |---|---|---|
  | 1 | Course Introduction and Laplace Introduction | 1 |
  | 2 | Transfer Functions and Modeling | 2 |
  | 3 | Class cancelled | — |
  | 4 | Lab 1: USV System Identification | 3 |
  | 5 | Time Response | 4 |
  | 6 | Block Diagrams, Feedback and Steady-State Errors | 5 + 6 |
  | 7 | Lab 2: USV PID Tuning | 7 |
  | 8 | Frequency Response | 8 |
  | 9 | Compensation Design with Frequency Response | 9 (plus the frequency-response items from the wiki Video Lectures page, still to migrate) |
  | 10 | Lab 3: USV Navigation Tuning | 10 |
  | 11 | Final Oral Exams | 11 |

- Notes for posting:
  - Week 6: refactor the weekly content to fold in just the basics of what steady-state error "is" and skip over how to do the analysis.
  - Week 9: HW5 and Lab 2 fall due Fri 27 Nov, the day after Thanksgiving; confirm the due date when posting.
