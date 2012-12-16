% Totally uninteresing preamble
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{skdoc}[2012/12/15 v0.0 skdoc documentation class]
\RequirePackage{kvoptions,xstring,etoolbox,xparse,l3tl,l3int,%
				l3file,verbatim,xcolor}

% Define some options
\SetupKeyvalOptions{
	family=skdoc,
	prefix=skdoc@
}
\DeclareStringOption{load}[\jobname] % Load given package
\ProcessKeyvalOptions*

% Optionally load the package
\IfStrEq{\skdoc@load}{}{}{%
	\IfFileExists{\skdoc@load.sty}{%
		\RequirePackage{\skdoc@load}
	}{}
}

% Is this the first run?
\newtoggle{skdoc@first}
\toggletrue{skdoc@first}
\IfFileExists{\jobname.aux}{
	\togglefalse{skdoc@first}
}{}

%% Writing to a file
%% All this code need better error checking
\ExplSyntaxOn
%\DeclareDocumentCommand\skdoc@openfile{}{}
\iow_new:N\skdoc@output
% This declares a file as part of the bundle,
% we will be writing things to it.
%TODO: possibly allow an alias instead
\DeclareDocumentCommand\DeclareFile{m}{
	\tl_new:c{skdoc@output@#1}
	\int_if_exist:cTF{skdoc@output@#1@line}{
		\ClassError{skdoc}{File\space key\space #2\space already\space declared!}
	}{
		\int_zero_new:c{skdoc@output@#1@line}
	}
	\AtEndDocument{
		\iow_open:Nn\skdoc@output{#2}
		\iow_now:Nx\skdoc@output{\tl_to_str:c{skdoc@output@#1}}
		\iow_close:N\skdoc@output
	}
}
% Save all the code in token lists, and also print it.
\DeclareDocumentEnvironment{skdoc@verbatim}{m}{%
	\@bsphack
	\int_if_exist:cTF{skdoc@output@#1@line}{}{
		\ClassError{skdoc}{File\space #1\space undeclared!}
	}%
	\def\verbatim@processline{%
		\tl_gput_right:cx{skdoc@output@#1}{\the\verbatim@line\iow_newline:}%
		\int_gincr:c{skdoc@output@#1@line}%
		\leavevmode%
		\llap{%
			\scriptsize\color{lightgray}%
			\int_use:c{skdoc@output@#1@line}\ \ \hskip\@totalleftmargin%
		}%
		{\verbatim@font\the\verbatim@line}\par%
	}%
	\let\do\@makeother\dospecials\catcode`\^^M\active%
	\frenchspacing\@vobeyspaces\verbatim@start%
}{%
	\@esphack%
}
\DeclareDocumentEnvironment{MacroCode}{m}{
	\par
	\skdoc@verbatim{#1}
}{
	\endskdoc@verbatim
}
\ExplSyntaxOff

% For the rest, see ydoc.dtx and http://tex.stackexchange.com/questions/47237/different-approach-to-literate-programming-for-latex
\LoadClass{scrartcl}
\RequirePackage{ydoc}

%% We need a way to insert a preamble to the files.
