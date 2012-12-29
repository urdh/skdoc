## skdoc documentation class
##
## Copyright (C) 2012 by Simon Sigurdhsson <sigurdhsson@gmail.com>
## 
## This work may be distributed and/or modified under the
## conditions of the LaTeX Project Public License, either version 1.3
## of this license or (at your option) any later version.
## The latest version of this license is in
##   http://www.latex-project.org/lppl.txt
## and version 1.3 or later is part of all distributions of LaTeX
## version 2005/12/01 or later.
## 
## This work has the LPPL maintenance status `maintained'.
## 
## The Current Maintainer of this work is Simon Sigurdhsson.
## 
## This work consists of the files skdoc.dtx and Makefile
## and the derived filebase skdoc.cls.
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
