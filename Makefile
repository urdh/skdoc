TEXMFHOME ?= $(shell kpsewhich -var-value TEXMFHOME)
.PHONY: all clean distclean install
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
