# Start-of-Quarter Checklist

Run through this every term before the first class meeting.

- [ ] Tag the previous quarter: `git tag site-YYYY-season && git push --tags`
- [ ] Update `_variables.yml`: `quarter`, `term_start`, `term_end`
- [ ] Update `data/schedule.yml`: dates, topics, due items, week types
- [ ] Update `data/assignments.yml`: due dates
- [ ] Skim `index.qmd` and `syllabus.qmd` for stale references (term, dates, links)
- [ ] Skim `weeks/wXX_*.qmd` for stale per-quarter content (video links, slide handouts)
- [ ] Bump office hours / contact info in `syllabus.qmd` if changed
- [ ] Local preview: `cd site && quarto preview`
- [ ] Push and verify the published site after the Action runs
