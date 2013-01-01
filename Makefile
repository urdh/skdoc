.PHONY: all clean distclean
all: skdoc.cls skdoc.pdf
clean:
	rm -f skdoc.cls
distclean: clean

%.cls:
	tex $*.dtx

%.pdf:
	pdflatex $*.dtx
	makeglossaries $*
	biber $*
	pdflatex $*.dtx
	makeglossaries $*
	pdflatex $*.dtx
