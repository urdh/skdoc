TEXMFHOME ?= $(shell kpsewhich -var-value TEXMFHOME)
.PHONY: all clean distclean install dist test clean-test
all: skdoc.dtx skdoc.cls skdoc.pdf README
clean: clean-test
	rm -f *.gl? *.id? *.aux # problematic files
	rm -f *.bbl *.bcf *.bib *.blg *.xdy # biblatex
	rm -f *.fls *.log *.out *.run.xml *.toc # junk
distclean: clean
	rm -f *.cls *.sty *.clo *.tar.gz *.tds.zip README
	git reset --hard

%.cls: %.dtx
	tex $<

%.pdf: %.dtx
	pdflatex -interaction=nonstopmode -halt-on-error $<
	makeglossaries $*
	biber $*
	pdflatex -interaction=nonstopmode -halt-on-error $<
	makeglossaries $*
	pdflatex -interaction=nonstopmode -halt-on-error $<

README: README.md
	sed -e '1,4d;$$d' $< > $@

install: all
	install -m 0644 skdoc.cls $(TEXMFHOME)/tex/latex/skdoc/skdoc.cls
	install -m 0644 skdoc.pdf $(TEXMFHOME)/doc/latex/skdoc/skdoc.pdf
	install -m 0644 skdoc.tex $(TEXMFHOME)/source/latex/skdoc/skdoc.dtx
	install -m 0644 README $(TEXMFHOME)/doc/latex/skdoc/README
	-mktexlsr

skdoc.tds.zip: all
	mkdir -p skdoc/tex/latex/skdoc
	cp skdoc.cls skdoc/tex/latex/skdoc/skdoc.cls
	mkdir -p skdoc/doc/latex/skdoc
	cp skdoc.pdf skdoc/doc/latex/skdoc/skdoc.pdf
	mkdir -p skdoc/source/latex/skdoc
	cp skdoc.dtx skdoc/source/latex/skdoc/skdoc.dtx
	cp README skdoc/doc/latex/skdoc/README
	cd skdoc && zip -r ../skdoc.tds.zip *
	rm -rf skdoc

skdoc.tar.gz: all skdoc.tds.zip
	mkdir -p skdoc
	cp skdoc.dtx skdoc/skdoc.dtx
	cp skdoc.pdf skdoc/skdoc.pdf
	cp README skdoc/README
	cp Makefile skdoc/Makefile
	tar -czf $@ skdoc skdoc.tds.zip
	rm -rf skdoc

dist: skdoc.tar.gz

test:
#	$(MAKE) -C tests

clean-test:
#	$(MAKE) -C tests clean
