% Totally uninteresing preamble
%
% TODO:
% Convert things to LaTeX3-ish ways of doing it!
% And get rid of those end-of-line commends, we
% don't need them with expl3 syntax.
%
% Implement a way to disable the code listings (and
% text detailing the implementation) while still writing
% the code to the target file.
%
% Restructure the code.
\NeedsTeXFormat{LaTeX2e}
\RequirePackage{expl3}
\ProvidesExplClass{skdoc}{2012/12/19}{0.0}{Documentation class}
\RequirePackage{kvoptions,xstring,etoolbox,xparse,verbatim,xcolor}

% Set up some message texts!
\msg_new:nnn{skdoc}{key-exists}{File~key~"#1"~already~declared!}
\msg_new:nnn{skdoc}{key-nexists}{File~key~"#1"~hasn't~been~declared!}
\msg_new:nnn{skdoc}{wrote-file}{Writing~things~to~file~"#1".}
\msg_new:nnn{skdoc}{read-preamble}{Reading~preamble~from~file~"#1".}

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
		\msg_critical:nnx{skdoc}{key-exists}{\skdoc@key}
	}{
		\int_zero_new:c{skdoc@output@\skdoc@key @line}
	}
	\expandafter\xdef\csname skdoc@write@#2\endcsname{%
		\noexpand\msg_log:nnn{skdoc}{wrote-file}{#2}
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
	\int_if_exist:cTF{skdoc@output@\skdoc@key @line}{}{
		\msg_critical:nnx{skdoc}{key-nexists}{\skdoc@key}
	}%
	\def\verbatim@processline{%
		\tl_gput_right:cx{skdoc@output@\skdoc@key}{\the\verbatim@line\iow_newline:}%
		\int_gincr:c{skdoc@output@\skdoc@key @line}%
		\leavevmode%
		\hspace*{-5ex}
		\begin{minipage}[c][1ex]{\textwidth}
			\makebox[4ex]{%
				\leavevmode
				\tiny\color{lightgray}\hfill%
				\int_use:c{skdoc@output@\skdoc@key @line}%
			}%
			\hspace*{1ex}%
			{
				\verbatim@font\footnotesize
				\the\verbatim@line
			}
		\end{minipage}
		\vskip-.75ex\par\noindent
	}%
	\let\do\@makeother\dospecials\catcode`\^^M\active%
	\frenchspacing\@vobeyspaces\verbatim@start%
}{%
	\@esphack%
}
\DeclareDocumentEnvironment{MacroCode}{m}{
	\vspace{.5\baselineskip}
	\par\noindent
	\skdoc@verbatim{#1}
}{
	\endskdoc@verbatim
	\vskip\baselineskip
}
%% Read preamble from a document and store in variable
\DeclareDocumentCommand\PreambleTo{mm}{%
	\group_begin:
	\msg_info:nnn{skdoc}{read-preamble}{#2}
	\ior_open:Nn\skdoc@input{#2}
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
% Read preamble from current document
\DeclareDocumentCommand\SelfPreambleTo{m}{%
	\PreambleTo{#1}{\c_job_name_tl}%
}
% \SelfPreamble, y u no work?
\DeclareDocumentCommand\SelfPreamble{}{%
	\SelfPreambleTo{\skdoc@preambletemp}%
	\skdoc@preambletemp%
}

% For the rest, see ydoc.dtx and http://tex.stackexchange.com/questions/47237/different-approach-to-literate-programming-for-latex
\LoadClass[DIV7,headings=big,numbers=noenddot,%
		   abstracton,bibliography=totoc,index=totoc]{scrartcl}
\RequirePackage[british]{babel}
\RequirePackage{scrpage,calc,shortvrb,url,hyperref}
\RequirePackage[nomain,xindy,numberedsection,order=letter,%
				sanitize={description=false,sort=false}]{glossaries}
\RequirePackage{ydoc-code} %reimplement?
\RequirePackage{ydoc-desc} %reimplement?
\RequirePackage{PTSerif,ascii}%,PTMono}
\RequirePackage[defaultsans,osfigures,scale=0.95]{opensans}
\AtBeginDocument{\MakeShortVerb{\|}}

% Colors! (and fonts)
\RenewDocumentCommand\descfont{}{\sffamily}
\RenewDocumentCommand\sectfont{}{\sffamily}
\providecolorset{RGB}{skdoc@color@}{}{
	section,11,72,107;
	extlink,73,10,61;
	intlink,140,35,24;
	sharp,250,105,0;
	bright,198,229,217
}
% y u no work?
\definecolorset{RGB}{}{}{
	macrodesc,73,10,61;
	keydesc,140,35,24;
	macroimpl,73,10,61;
	meta,11,72,107;
	scriptcolor,140,35,24;
	optioncolor,250,105,0
}
\colorlet{opt}{optioncolor}
\hypersetup{
	colorlinks=true,
	linkcolor=skdoc@color@intlink,
	anchorcolor=skdoc@color@intlink,
	citecolor=black,
	urlcolor=skdoc@color@extlink
}
\addtokomafont{minisec}{\bfseries}
\addtokomafont{paragraph}{\color{skdoc@color@section}}
\addtokomafont{section}{\color{skdoc@color@section}}
\addtokomafont{subsection}{\color{skdoc@color@section}}
\addtokomafont{subsubsection}{\color{skdoc@color@section}}
\addtokomafont{descriptionlabel}{\color{skdoc@color@section}}

%% Bugfixing ydoc
\def\PrintEnvImplName#1{%
  \par\bigskip\noindent
  \hbox{\hspace*{\descindent}\fbox{{\implstyle{#1}\strut}}}%
  \par\medskip
}
%% Hacking some ydoc features
\DeclareDocumentCommand\generalname{}{General}
\DeclareDocumentCommand\@macroname{m}{
	\def\skdoc@macroname@stylized{\cs{\expandafter\@gobble\string#1}}
	\def\skdoc@macroname@key{macro-\expandafter\@gobble\string#1}
}
\DeclareDocumentCommand\@environmentname{m}{
	\def\skdoc@macroname@stylized{\env{\string#1}}
	\def\skdoc@macroname@key{env-#1}
}
\def\skdoc@macroname@stylized{}
\let\skdoc@macroname@key\@empty
\DeclareDocumentEnvironment{macro}{mo}{%
	\index@macro{#1}
	\@macroname{#1}%
	\PrintMacroImpl{#1}%
	\IfNoValueTF{#2}{}{\macro@impl@args[#2]}
}{
	\let\skdoc@macroname@key\@empty
}
\DeclareDocumentEnvironment{environment}{mo}{%
	\index@environment{#1}
	\@environmentname{#1}%
	\PrintEnvImplName{#1}%
	\IfNoValueTF{#2}{}{\macro@impl@args[#2]}
}{
	\let\skdoc@macroname@key\@empty
}

%% The usual documentation stuff (not all of it)
\newglossary{changes}{gls}{glo}{Changes}
\newglossarystyle{changelog}{
	\glossarystyle{altlist}
	\renewcommand*{\glossaryentryfield}[5]{
		\item[\glsentryitem{##1}\glstarget{##1}{##2}]
				\mbox{}\par\nobreak\@afterheading
	}
}
\AtBeginDocument{\makeglossaries}
\DeclareDocumentCommand\changes{mm}{%
	\@bsphack
	\ifglsentryexists{#1}{}{
		\newglossaryentry{#1}{
			type=changes,
			name={v#1},
			description={\nopostdesc},
			nonumberlist=true
		}
	}
	\ifx\skdoc@macroname@key\@empty
		\newglossaryentry{#1-general}{
			type=changes,
			description={\generalname{}:~#2},
			parent={#1},
			sort={0}
		}
		\glsadd[types=changes]{#1-general}
	\else
		\newglossaryentry{#1-\skdoc@macroname@key}{
			type=changes,
			description={\skdoc@macroname@stylized{}:~#2},
			parent={#1},
			sort={\skdoc@macroname@key}
		}
		\glsadd[types=changes]{#1-\skdoc@macroname@key}
	\fi
	\@esphack
}
\DeclareDocumentCommand\PrintChanges{}{%
	\begingroup
	\printglossary[type=changes,style=changelog]
	\endgroup
}

%% Indexing!
\newglossary{index}{ids}{ido}{Index}
\newglossarystyle{docindex}{
	\glossarystyle{indexgroup}
	\renewcommand*{\glossaryentryfield}[5]{
		\item\glsentryitem{##1}\glstarget{##1}{##2}
  			\ifx\relax##4\relax\else\space(##4)\fi
  			\space ##3\glspostdescription \space ##5}
}
\DeclareDocumentCommand\@index@{mm}{
	\newglossaryentry{index-#1}{
		type=index,
		name={#2},
		description={\nopostdesc},
		sort={#1}
	}
}
\let\old@PrintMacroName\PrintMacroName
\DeclareDocumentCommand\PrintMacroName{m}{%
	\index@macro{#1}
	\old@PrintMacroName{#1}
}
\DeclareDocumentCommand\index@macro{m}{
	\def\skdoc@temp{\expandafter\@gobble\string#1}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\expandafter\@gobble\string#1}
				{\cs{\expandafter\@gobble\string#1}}
	}
	\glsadd[types=index]{index-\skdoc@temp}
}
\let\old@PrintEnvName\PrintEnvName
\def\PrintEnvName#1#2{
	\ifx#1\begin
		\edef\skdoc@temp{\noexpand\index@environment{#2}}
		\skdoc@temp
	\fi
	\old@PrintEnvName{#1}{#2}
}
\DeclareDocumentCommand\index@environment{m}{
	\def\skdoc@temp{\string#1}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\string#1}
				{\env{\string#1}~(environment)}
	}
	\glsadd[types=index]{index-\skdoc@temp}
}
\providecommand*\PrintIndex{%
	\begingroup
	\renewcommand*{\glossarypreamble}{
%	
	}
	\printglossary[type=index,style=docindex]
	\endgroup
}

%% Document metadata
\DeclareDocumentCommand\package{om}{%
	\keys_define:nn{skdoc@package}{%
		vcs .value_required:,%
		vcs .code:n = \repository{##1},%
		ctan .code:n = \ctan{##1},%
		ctan .default:n = #2%
	}%
	\IfNoValueTF{#1}{}{\keys_set:nn{skdoc@package}{#1}}%
	\def\@package{#2}%
	\title{The~\textsf{\textbf{\@package}}~document~class}%
}
\DeclareDocumentCommand\ctan{m}{%
	\def\@ctan{\url{http://www.ctan.org/pkg/#1}}%
}
\DeclareDocumentCommand\repository{m}{%
	\def\@repository{\url{#1}}%
}
\DeclareDocumentCommand\email{m}{%
	\def\@plainemail{#1}%
	\def\@email{\href{mailto:\@plainemail}{\@plainemail}}%
}
\DeclareDocumentCommand\version{m}{%
	\def\@version{#1}%
}
\package[ctan]{skdoc}
% Default metadata
\let\@ctan\@empty%
\let\@repository\@empty%
\let\@plainemail\@empty%
\let\@email\@empty%
\let\@version\@empty%
\package{\jobname}
%\ExplSyntaxOff

%% An environment to specify examples
\DeclareDocumentEnvironment{example}{}{
	\minisec{Example:}
}{}

%% PDF information
\ifpdf
	\def\skdocpdfsettings{%
	    \hypersetup{%
	        pdfauthor   = {\@author\space<\@plainemail>},
	        pdftitle    = {\@title},
	        pdfsubject  = {Documentation~of~LaTeX~package~\@package},
	        pdfkeywords = {\@package,~LaTeX,~TeX}
	    }%
	}%
\else
	\let\skdocpdfsettings\empty%
\fi

% Also, new maketitle
\def\@maketitle{%
	\newpage
	\null
	\begin{flushleft}%
	{%
		\Huge\sectfont\@title%
		\ifx\@ctan\@empty\else%
			\footnote{Available~on~\@ctan.}%
		\fi
		\ifx\@repository\@empty\else%
			\footnote{Development~version~available~on~\@repository.}%
		\fi%
		\par%
	}%
	\vskip 1em
	{%
		\Large\@author
		\ifx\@email\@empty\else%
			\space
			\newlength\skdoc@minipage@ew%
			\settowidth{\skdoc@minipage@ew}{%
				\normalsize{$\lceil${\@email}$\rfloor$}}
			\begin{minipage}[b]{\skdoc@minipage@ew}
				\normalsize{$\lceil${\@email}$\rfloor$}
			\end{minipage}\par%
		\fi%
	}%
	\ifx\@version\@empty\else
		\vskip .5em
		{%
			\large Version~\@version\par%
		}%
	\fi
	\end{flushleft}%
	\par\bigskip%
}

\def\maketitle{%
    \skdocpdfsettings
    \renewcommand\thefootnote{\@fnsymbol\c@footnote}
    \@maketitle
    \skdocpdfsettings
}
% And abstract
\DeclareDocumentEnvironment{abstract}{}{
	\newlength\skdoc@abstract@tw%
	\newlength\skdoc@abstract@aw%
	\settowidth{\skdoc@abstract@tw}{\descfont\abstractname}%
	\setlength{\skdoc@abstract@aw}{\the\textwidth-\the\skdoc@abstract@tw-1.5em}%
	\begin{minipage}{\textwidth}
		\begin{minipage}[t]{\skdoc@abstract@tw}%
			\begin{flushright}%
				\leavevmode\descfont\abstractname%
			\end{flushright}%
		\end{minipage}%
		\hfill%\hspace{1em}%
		\begin{minipage}[t]{\skdoc@abstract@aw}%
}{
		\end{minipage}
	\end{minipage}
}
% And the header/footer
\deftripstyle{skdoc}%
	{}{}{}%
	{\small The~\textsf{\textbf{\@package}}~package,~v\@version}{}{\small\pagemark}
\AfterBeginDocument{\pagestyle{skdoc}}




