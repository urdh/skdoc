TEXMFHOME ?= $(shell kpsewhich -var-value TEXMFHOME)
.PHONY: all clean distclean install dist
all: skdoc.cls skdoc.pdf
clean:
	rm -f skdoc.cls
distclean: clean

%.cls: %.dtx
	tex $<

%.pdf: %.dtx
	pdflatex $<
	makeglossaries $*
	biber $*
	pdflatex $<
	makeglossaries $*
	pdflatex $<

install: all
	install -m 0644 skdoc.cls $(TEXMFHOME)/tex/latex/skdoc/skdoc.cls
	install -m 0644 skdoc.pdf $(TEXMFHOME)/doc/latex/skdoc/skdoc.pdf
	install -m 0644 skdoc.tex $(TEXMFHOME)/source/latex/skdoc/skdoc.dtx
	install -m 0644 README $(TEXMFHOME)/doc/latex/skdoc/README
	-mktexlsr

skdoc.tds.zip: skdoc.dtx skdoc.pdf skdoc.cls
	mkdir -p skdoc/{tex,doc,source}/latex/skdoc
	cp skdoc.cls skdoc/tex/latex/skdoc/skdoc.cls
	cp skdoc.pdf skdoc/doc/latex/skdoc/skdoc.pdf
	cp skdoc.dtx skdoc/source/latex/skdoc/skdoc.dtx
	cp README skdoc/doc/latex/skdoc/README
	cd skdoc && zip -r ../skdoc.tds.zip *
	rm -rf skdoc

skdoc.tar.gz: skdoc.tds.zip skdoc.dtx skdoc.pdf
	mkdir -p skdoc
	cp skdoc.dtx skdoc/skdoc.dtx
	cp skdoc.pdf skdoc/skdoc.pdf
	cp README skdoc/README
	cp Makefile skdoc/Makefile
	tar -czf $@ skdoc skdoc.tds.zip
	rm -rf skdoc

dist: skdoc.tar.gz
