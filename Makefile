# Repo workflow targets for the public + private repo pair.
#
# This repo is public. A sibling private repo lives at ./private/ and
# tracks bsb808/introduction-to-feedback-control-private. The targets
# below operate on both repos so you can pull/push both in one step.
#
# (LaTeX builds live in book/Makefile — this file is just for git plumbing.)

PRIVATE_DIR := private
PRIVATE_URL := git@github.com:bsb808/introduction-to-feedback-control-private.git

.PHONY: help status pull push fetch sync clone-private

help:
	@echo "Repo workflow targets:"
	@echo "  make status         git status of both repos"
	@echo "  make pull           git pull on both"
	@echo "  make push           git push on both"
	@echo "  make fetch          git fetch on both (no merge)"
	@echo "  make sync           pull, then push, on both"
	@echo "  make clone-private  one-time setup: clone the private sibling repo into ./$(PRIVATE_DIR)/"

status:
	@echo "==== public ===="
	@git status -sb
	@echo
	@echo "==== private ===="
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  cd $(PRIVATE_DIR) && git status -sb; \
	else \
	  echo "(not cloned — run 'make clone-private')"; \
	fi

pull:
	@echo "==== pulling public ===="
	git pull
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  echo; echo "==== pulling private ===="; \
	  cd $(PRIVATE_DIR) && git pull; \
	else \
	  echo "(skipping private — not cloned; run 'make clone-private')"; \
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

clone-private:
	@if [ -d $(PRIVATE_DIR)/.git ]; then \
	  echo "$(PRIVATE_DIR)/ already a git repo — nothing to do"; \
	else \
	  git clone $(PRIVATE_URL) $(PRIVATE_DIR); \
	fi
