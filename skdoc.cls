% Totally uninteresing preamble
% Consider doing it the LaTeX3 way?
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{skdoc}[2012/12/15 v0.0 skdoc documentation class]
\RequirePackage{kvoptions,xstring,etoolbox,xparse,l3tl,l3int,%
				l3file,l3keys,l3prg,verbatim,xcolor}

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
\tl_new:N\skdoc@temptl
\ior_new:N\skdoc@input
\iow_new:N\skdoc@output
% This declares a file as part of the bundle,
% we will be writing things to it.
\DeclareDocumentCommand\DeclareFile{om}{
	\group_begin:
	\keys_define:nn{skdoc@declarefile}{%
		preamble .value_required:,
		preamble .code:n = \edef\skdoc@preamble{##1},
		key .value_required:,
		key .code:n = \def\skdoc@key{##1}
	}%
	\def\skdoc@preamble{}%
	\def\skdoc@key{#2}%
	\IfNoValueTF{#1}{}{\keys_set:nn{skdoc@declarefile}{#1}}
	\tl_new:c{skdoc@output@\skdoc@key}
	\int_if_exist:cTF{skdoc@output@\skdoc@key @line}{
		\ClassError{skdoc}{File\space key\space \skdoc@key\space already\space declared!}
	}{
		\int_zero_new:c{skdoc@output@\skdoc@key @line}
	}
	\expandafter\xdef\csname skdoc@write@#2\endcsname{%
		\noexpand\iow_open:Nn\noexpand\skdoc@output{#2}
		\noexpand\IfStrEq{\skdoc@preamble}{}{}{
			\noexpand\iow_now:Nx\noexpand\skdoc@output{\skdoc@preamble}
		}
		\noexpand\iow_now:Nx\noexpand\skdoc@output{\noexpand\tl_to_str:c{skdoc@output@\skdoc@key}}
		\noexpand\iow_close:N\noexpand\skdoc@output
	}
	\AfterEndDocument{\csname skdoc@write@#2\endcsname}
	\group_end:
}
% Save all the code in token lists, and also print it.
\DeclareDocumentEnvironment{skdoc@verbatim}{m}{%
	\@bsphack
	\def\skdoc@key{#1}
	\int_if_exist:cTF{skdoc@output@#1@line}{}{
		\ClassError{skdoc}{File\space \skdoc@key\space undeclared!}
	}%
	\def\verbatim@processline{%
		\tl_gput_right:cx{skdoc@output@\skdoc@key}{\the\verbatim@line\iow_newline:}%
		\int_gincr:c{skdoc@output@\skdoc@key @line}%
		\leavevmode%
		\llap{%
			\scriptsize\color{lightgray}%
			\int_use:c{skdoc@output@\skdoc@key @line}\ \ \hskip\@totalleftmargin%
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
%% Read preamble from current document and store in variable
\DeclareDocumentCommand\SelfPreambleTo{m}{%
	\group_begin:
	\ior_open:Nn\skdoc@input{\c_job_name_tl}
	\bool_until_do:nn{\ior_if_eof_p:N\skdoc@input}{%
		\tl_if_empty:NTF\skdoc@temptl{}{%
			\tl_put_right:Nx\skdoc@temptl{\iow_newline:}
		}
		\tl_clear:N\l_tmpb_tl
		\ior_get_str:NN\skdoc@input\l_tmpa_tl
		\tl_put_right:Nx\l_tmpb_tl{\tl_head:N\l_tmpa_tl}
		\IfStrEq{\tl_to_str:N\l_tmpb_tl}{\@percentchar}{%
			\tl_set_eq:NN\l_tmpb_tl\skdoc@temptl
			\tl_concat:NNN\skdoc@temptl\l_tmpb_tl\l_tmpa_tl
		}{%
			\ior_close:N\skdoc@input
		}
	}
	\xdef#1{\tl_to_str:N\skdoc@temptl}
	\group_end:
}
% \SelfPreamble, y u no work?
\DeclareDocumentCommand\SelfPreamble{}{%
	\SelfPreambleTo{\skdoc@preambletemp}
	\skdoc@preambletemp
}
\ExplSyntaxOff

% For the rest, see ydoc.dtx and http://tex.stackexchange.com/questions/47237/different-approach-to-literate-programming-for-latex
\LoadClass{scrartcl}
\RequirePackage{ydoc}

% Also, hack the maketitle
\def\@maketitle{%
    \newpage
    \null\vskip 2em
    \begin{center}%
        {%
        	\LARGE \@title%
        	\footnote{Available on \@homepage.}%
        	\ifx\@repository\@empty\else%
            \hspace{1ex}\footnote{Development version available on \@repository.}%
        	\fi%
         	\par%
        }\vskip 1.5em%
        \ifx\@bundle\@empty\else
        {\large \@bundlesubtitle \par }\vskip 1.5em%
        \fi
        {\large \lineskip .5em%
        \begin{tabular}[t]{c}%
            \@author
        \end{tabular}%
        \par}%
        \ifx\@plainemail\empty\else
            {\large \lineskip .5em%
            \begin{tabular}[t]{c}%
                \@email
            \end{tabular}%
            \par}%
        \fi
        \vskip 1em
        {\large \@date }%
    \end{center}%
    \par\vskip 1.5em
    \aftergroup\ydocpdfsettings
}

%% We need a way to insert a preamble to the files.
