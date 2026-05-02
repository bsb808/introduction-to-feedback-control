# Makefile for ME 2801 — Introduction to Feedback Control
#
# Builds standalone chapters, assignments, and the master book PDF.
# All PDFs are written alongside their .tex source.

LATEXMK := latexmk -pdf -interaction=nonstopmode -f

CHAPTERS_TEX    := $(wildcard w*/chapter/*.tex)
CHAPTERS_PDF    := $(CHAPTERS_TEX:.tex=.pdf)
ASSIGNMENTS_TEX := $(wildcard w*/assign/*.tex)
ASSIGNMENTS_PDF := $(ASSIGNMENTS_TEX:.tex=.pdf)

WEEK_NUMS    := 01 02 03 04 05 06 07 08 09 10
WEEK_TARGETS := $(addprefix w,$(WEEK_NUMS))

.PHONY: all chapters assignments book clean distclean help $(WEEK_TARGETS)

all: chapters assignments book

help:
	@echo "Targets:"
	@echo "  all          Build every chapter standalone, every assignment, and the book"
	@echo "  book         Build book.pdf"
	@echo "  chapters     Build all standalone chapter PDFs"
	@echo "  assignments  Build all assignment PDFs"
	@echo "  wNN          Build chapter + assignment for week NN (e.g. make w01)"
	@echo "  clean        Remove latexmk aux files (keep PDFs)"
	@echo "  distclean    Remove all generated files including PDFs"

chapters: $(CHAPTERS_PDF)
assignments: $(ASSIGNMENTS_PDF)
book: book.pdf

book.pdf: book.tex $(CHAPTERS_TEX)
	$(LATEXMK) -cd $< || test -f $@

$(CHAPTERS_PDF) $(ASSIGNMENTS_PDF): %.pdf: %.tex
	$(LATEXMK) -cd $< || test -f $@

# Per-week shortcut: make w01, make w02, ...
define week_rule
w$(1): $(patsubst %.tex,%.pdf,$(wildcard w$(1)_*/chapter/*.tex)) \
       $(patsubst %.tex,%.pdf,$(wildcard w$(1)_*/assign/*.tex))
endef
$(foreach n,$(WEEK_NUMS),$(eval $(call week_rule,$(n))))

clean:
	@for f in $(CHAPTERS_TEX) $(ASSIGNMENTS_TEX) book.tex; do \
		latexmk -c -cd $$f >/dev/null 2>&1 || true; \
	done

distclean:
	@for f in $(CHAPTERS_TEX) $(ASSIGNMENTS_TEX) book.tex; do \
		latexmk -C -cd $$f >/dev/null 2>&1 || true; \
	done
