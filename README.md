[![Github CI](https://img.shields.io/github/actions/workflow/status/urdh/skdoc/continuous-integration.yml)](https://github.com/urdh/skdoc/actions/workflows/continuous-integration.yml)
[![CTAN: Version](https://img.shields.io/ctan/v/skdoc)](http://www.ctan.org/pkg/skdoc)
[![CTAN: License](https://img.shields.io/ctan/l/skdoc)](http://www.ctan.org/pkg/skdoc)
```
%% skdoc documentation class
%%
%% Copyright (C) 2012-2025 by Simon Sigurdhsson <sigurdhsson@gmail.com>
%%
%% This work may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, either version 1.3
%% of this license or (at your option) any later version.
%% The latest version of this license is in
%%   http://www.latex-project.org/lppl.txt
%% and version 1.3 or later is part of all distributions of LaTeX
%% version 2005/12/01 or later.
%%
%% This work has the LPPL maintenance status `maintained'.
%%
%% The Current Maintainer of this work is Simon Sigurdhsson.
%%
%% This work consists of the files skdoc.dtx
%% and the derived filebase skdoc.cls.

This is version 1.5e of the skdoc document class. It is designed to
generate both documentation and derivative files using only LaTeX,
i.e. without using docstrip and ins/dtx files.

The following files are enclosed.

  README        - This file
  Makefile      - GNU Makefile for making the package and documentation
  skdoc.dtx     - LaTeX source code of the package
  skdoc.pdf     - PDF version of the documentation

Installation notes:
The easiest way to install this package, assuming you have obtained the
source code from Github or CTAN, is to simply run `make install`. This
will generate package code and documentation, install it into TEXMFHOME
and run `mktexlsr`. If you wish to compile the package but not install
it, run `make all` instead. If you insist on doing it manually, remember
to run `tex` to generate the code, and `pdflatex` (or `latex`, if you
don't fancy PDFs) to generate the documentation.
```
