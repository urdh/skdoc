.PHONY: all clean distclean
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
