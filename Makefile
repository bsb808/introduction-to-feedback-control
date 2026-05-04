# Repo workflow targets for the three-repo trio: public, private, and
# Claude Code session history.
#
# Layout (umbrella convention): all three repos as siblings under an
# umbrella directory. Claude Code is launched from the umbrella, which is
# also the project root that determines the session-storage slug.
#
#   <umbrella>/
#     introduction-to-feedback-control/          (this repo, public)
#     introduction-to-feedback-control-private/  (sibling, instructor-only)
#     introduction-to-feedback-control-claude/   (sibling, session history)
#
# Two-repo targets (public + private):
#   make status / pull / push / fetch / sync
# Three-repo targets (public + private + claude):
#   make status-all / pull-all / push-all / fetch-all / sync-all
# New-machine setup:
#   make clone-private / clone-claude / link-claude / doctor
#
# (LaTeX builds live in book/Makefile -- this file is just for git plumbing.)

PRIVATE_DIR := ../introduction-to-feedback-control-private
PRIVATE_URL := git@github.com:bsb808/introduction-to-feedback-control-private.git

CLAUDE_DIR := ../introduction-to-feedback-control-claude
CLAUDE_URL := git@github.com:bsb808/introduction-to-feedback-control-claude.git

.PHONY: help \
        status pull push fetch sync \
        status-all pull-all push-all fetch-all sync-all \
        status-claude pull-claude push-claude fetch-claude \
        clone-private clone-claude link-claude doctor

help:
	@echo "Two-repo targets (public + private):"
	@echo "  make status         git status of public + private"
	@echo "  make pull           git pull on both"
	@echo "  make push           git push on both"
	@echo "  make fetch          git fetch on both (no merge)"
	@echo "  make sync           pull, then push, on both"
	@echo
	@echo "Three-repo targets (also includes Claude session repo):"
	@echo "  make status-all     status of public + private + claude"
	@echo "  make pull-all       pull all three"
	@echo "  make push-all       push all three"
	@echo "  make fetch-all      fetch all three"
	@echo "  make sync-all       pull, then push, on all three"
	@echo
	@echo "Claude-only:"
	@echo "  make status-claude / pull-claude / push-claude / fetch-claude"
	@echo
	@echo "One-time setup (per machine):"
	@echo "  make clone-private  clone the private sibling repo at $(PRIVATE_DIR)"
	@echo "  make clone-claude   clone the claude sibling repo at $(CLAUDE_DIR)"
	@echo "  make link-claude    symlink Claude's project dir into the -claude repo"
	@echo "  make doctor         check layout invariants on this machine"

# ----- public + private (existing two-repo targets) --------------------

status:
	@echo "==== public ===="
	@git status -sb
	@echo
	@echo "==== private ===="
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  cd $(PRIVATE_DIR) && git status -sb; \
	else \
	  echo "(not cloned -- run 'make clone-private')"; \
	fi

pull:
	@echo "==== pulling public ===="
	git pull
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  echo; echo "==== pulling private ===="; \
	  cd $(PRIVATE_DIR) && git pull; \
	else \
	  echo "(skipping private -- not cloned; run 'make clone-private')"; \
	fi

push:
	@echo "==== pushing public ===="
	git push
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  echo; echo "==== pushing private ===="; \
	  cd $(PRIVATE_DIR) && git push; \
	fi

fetch:
	git fetch
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  cd $(PRIVATE_DIR) && git fetch; \
	fi

sync: pull push

# ----- claude session repo (single-repo targets) -----------------------

status-claude:
	@echo "==== claude ===="
	@if [ -d $(CLAUDE_DIR)/.git ]; then \
	  cd $(CLAUDE_DIR) && git status -sb; \
	else \
	  echo "(not cloned -- run 'make clone-claude')"; \
	fi

pull-claude:
	@if [ -d $(CLAUDE_DIR)/.git ]; then \
	  echo "==== pulling claude ===="; \
	  cd $(CLAUDE_DIR) && git pull; \
	else \
	  echo "(skipping claude -- not cloned; run 'make clone-claude')"; \
	fi

push-claude:
	@if [ -d $(CLAUDE_DIR)/.git ]; then \
	  echo "==== pushing claude ===="; \
	  cd $(CLAUDE_DIR) && git add -A && \
	  if ! git diff --cached --quiet; then \
	    git commit -m "sync sessions"; \
	  fi; \
	  git push; \
	else \
	  echo "(skipping claude -- not cloned; run 'make clone-claude')"; \
	fi

fetch-claude:
	@if [ -d $(CLAUDE_DIR)/.git ]; then \
	  cd $(CLAUDE_DIR) && git fetch; \
	fi

# ----- three-repo targets ----------------------------------------------

status-all: status status-claude
pull-all:   pull   pull-claude
push-all:   push   push-claude
fetch-all:  fetch  fetch-claude
sync-all:   pull-all push-all

# ----- one-time clone --------------------------------------------------

clone-private:
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  echo "$(PRIVATE_DIR)/ already a git repo -- nothing to do"; \
	else \
	  git clone $(PRIVATE_URL) $(PRIVATE_DIR); \
	fi

clone-claude:
	@if [ -d $(CLAUDE_DIR)/.git ]; then \
	  echo "$(CLAUDE_DIR)/ already a git repo -- nothing to do"; \
	else \
	  git clone $(CLAUDE_URL) $(CLAUDE_DIR); \
	  echo; \
	  echo "Now run: make link-claude"; \
	fi

# ----- Claude project-dir symlink (portable across OS / user / umbrella) -----
#
# Slug rule: ~/.claude/projects/<umbrella-abs-path-with-/-replaced-by->/
# Umbrella  = parent of this public repo (since make runs from the public repo).

link-claude:
	@UMBRELLA=$$(cd .. && pwd -P); \
	SLUG=$$(printf '%s' "$$UMBRELLA" | sed 's|/|-|g'); \
	TARGET="$$HOME/.claude/projects/$$SLUG"; \
	if [ ! -d $(CLAUDE_DIR)/.git ]; then \
	  echo "ERROR: $(CLAUDE_DIR) is not a git repo. Run 'make clone-claude' first."; \
	  exit 1; \
	fi; \
	SOURCE=$$(cd $(CLAUDE_DIR) && pwd -P); \
	echo "Umbrella : $$UMBRELLA"; \
	echo "Slug     : $$SLUG"; \
	echo "Target   : $$TARGET"; \
	echo "Source   : $$SOURCE"; \
	echo; \
	if [ -L "$$TARGET" ]; then \
	  cur=$$(readlink "$$TARGET"); \
	  if [ "$$cur" = "$$SOURCE" ]; then \
	    echo "OK: already symlinked to $$SOURCE"; exit 0; \
	  else \
	    echo "ERROR: $$TARGET is a symlink to $$cur (not $$SOURCE). Resolve manually."; exit 1; \
	  fi; \
	elif [ -d "$$TARGET" ]; then \
	  echo "Found a real directory at $$TARGET -- merging into $$SOURCE..."; \
	  for f in "$$TARGET"/*.jsonl; do \
	    [ -e "$$f" ] || continue; \
	    base=$$(basename "$$f"); \
	    if [ -e "$$SOURCE/$$base" ]; then \
	      echo "  conflict: $$base exists in both -- skipping"; \
	    else \
	      mv "$$f" "$$SOURCE/" && echo "  moved $$base"; \
	    fi; \
	  done; \
	  if [ -d "$$TARGET/memory" ]; then \
	    if [ -z "$$(ls -A "$$TARGET/memory" 2>/dev/null)" ]; then \
	      rmdir "$$TARGET/memory"; \
	    else \
	      echo "  $$TARGET/memory is non-empty; leaving in place for manual merge"; \
	    fi; \
	  fi; \
	  remaining=$$(ls -A "$$TARGET" 2>/dev/null); \
	  if [ -z "$$remaining" ]; then \
	    rmdir "$$TARGET" && ln -s "$$SOURCE" "$$TARGET" && echo "OK: linked $$TARGET -> $$SOURCE"; \
	  else \
	    echo "ERROR: $$TARGET still has files after merge:"; ls -la "$$TARGET"; \
	    echo "Resolve manually, then re-run 'make link-claude'."; exit 1; \
	  fi; \
	else \
	  mkdir -p "$$(dirname "$$TARGET")"; \
	  ln -s "$$SOURCE" "$$TARGET" && echo "OK: linked $$TARGET -> $$SOURCE"; \
	fi

# ----- Layout doctor: sanity-check the three-repo setup ----------------------

doctor:
	@UMBRELLA=$$(cd .. && pwd -P); \
	SLUG=$$(printf '%s' "$$UMBRELLA" | sed 's|/|-|g'); \
	TARGET="$$HOME/.claude/projects/$$SLUG"; \
	echo "Umbrella    : $$UMBRELLA"; \
	echo "Public repo : $$(pwd -P)"; \
	echo; \
	echo "Sibling repos:"; \
	for r in $(PRIVATE_DIR) $(CLAUDE_DIR); do \
	  if [ -d "$$r/.git" ]; then \
	    printf "  [OK]   %s\n" "$$r"; \
	  else \
	    printf "  [MISS] %s  (run the matching 'make clone-...')\n" "$$r"; \
	  fi; \
	done; \
	echo; \
	echo "Claude project link ($$TARGET):"; \
	if [ -L "$$TARGET" ]; then \
	  cur=$$(readlink "$$TARGET"); \
	  expected=$$(cd $(CLAUDE_DIR) 2>/dev/null && pwd -P); \
	  if [ "$$cur" = "$$expected" ]; then \
	    echo "  [OK]   symlink -> $$cur"; \
	  else \
	    echo "  [WARN] symlink -> $$cur"; \
	    echo "         expected -> $$expected"; \
	  fi; \
	elif [ -d "$$TARGET" ]; then \
	  echo "  [WARN] real directory, not a symlink -- sessions diverge from -claude repo"; \
	  echo "         run 'make link-claude' to fix"; \
	else \
	  echo "  [MISS] does not exist -- run 'make link-claude'"; \
	fi
