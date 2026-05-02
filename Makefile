# Repo workflow targets for the three-repo trio: public, private, and
# Claude Code session history.
#
# This repo is public.
#  * Sibling private repo at  ./private/                              (bsb808/introduction-to-feedback-control-private)
#  * Sibling claude   repo at ../introduction-to-feedback-control-claude/
#                                                                     (bsb808/introduction-to-feedback-control-claude)
#
# Two-repo targets (public + private):
#   make status / pull / push / fetch / sync
# Three-repo targets (public + private + claude):
#   make status-all / pull-all / push-all / fetch-all / sync-all
#
# (LaTeX builds live in book/Makefile -- this file is just for git plumbing.)

PRIVATE_DIR := private
PRIVATE_URL := git@github.com:bsb808/introduction-to-feedback-control-private.git

CLAUDE_DIR := ../introduction-to-feedback-control-claude
CLAUDE_URL := git@github.com:bsb808/introduction-to-feedback-control-claude.git

.PHONY: help \
        status pull push fetch sync \
        status-all pull-all push-all fetch-all sync-all \
        status-claude pull-claude push-claude fetch-claude \
        clone-private clone-claude

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
	@echo "One-time setup:"
	@echo "  make clone-private  clone the private sibling repo into ./$(PRIVATE_DIR)/"
	@echo "  make clone-claude   clone the claude sibling repo into $(CLAUDE_DIR)"

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
	  echo "Now symlink it into Claude Code's project directory:"; \
	  echo "  ln -s $$(realpath $(CLAUDE_DIR)) ~/.claude/projects/-home-bsb-WorkingCopies-introduction-to-feedback-control"; \
	fi
