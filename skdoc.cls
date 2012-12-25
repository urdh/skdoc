% Totally uninteresing preamble
%
% TODO:
% Convert things to LaTeX3-ish ways of doing it!
% And get rid of those end-of-line commends, we
% don't need them with expl3 syntax.
% This esp. goes for variable names.
%
% Nicer colors, especially for the code. And maybe make things
% typeset in the margin, might be good.
%
% Fix the implementation spec of things:
% - The argument list moves up on options, themes (and bibenty?)
% - The actual macro/env name probably needs \llap (check this
%   for the description commands as well)
% - They add a skip at the end of MacroCode. Or maybe they add an
%   empty line for starred environments. Figure this out. (MEH, made
%   it less pronounced by changing \vspace*s instead)
%
% Environment description needs to be more obvious.
%
% Index page numbers aligned to the right with dots?
%
% Way to describe themes in documentation.
%
% Show what file is being described in implementation?
%
% In the index, "@" should have its own header and not go under "default"
%
% Restructure the code. Split into sub-packages and load them. Maybe.
%
% Would it even be possible for this to use itself in a .dtx? Maybe
% use docstrip the first time and then load itself or something? Meh.
%
% \GetFileInfo could be simulated to set variables as \relax on first
% run then reading actual stuff from specified file on second run.
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
	\IfStrEq{\skdoc@preamble}{}{}{
		\tl_set:Nx\l_tmpa_tl{\skdoc@preamble}
		\edef\skdoc@temp{\tl_head:N\l_tmpa_tl}
		\def\skdoc@preamble@extra{
			\skdoc@temp\skdoc@temp\space~This~is~file~`#2',~generated~from~`\c_job_name_tl.tex'~(key~`\skdoc@key').
		}
	}
	\expandafter\xdef\csname skdoc@write@#2\endcsname{%
		\noexpand\msg_log:nnn{skdoc}{wrote-file}{#2}
		\noexpand\iow_open:Nn\noexpand\skdoc@output{#2}
		\noexpand\IfStrEq{\skdoc@preamble}{}{}{
			\noexpand\iow_now:Nx\noexpand\skdoc@output{\skdoc@preamble@extra}
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
	\iftoggle{skdoc@impl}{\@bsphack}{}
	\def\skdoc@key{#1}
	\int_if_exist:cTF{skdoc@output@\skdoc@key @line}{}{
		\msg_critical:nnx{skdoc}{key-nexists}{\skdoc@key}
	}%
	\def\verbatim@processline{%
		\tl_gput_right:cx{skdoc@output@\skdoc@key}{\the\verbatim@line\iow_newline:}%
		\int_gincr:c{skdoc@output@\skdoc@key @line}%
		\iftoggle{skdoc@impl}{
			\noindent\leavevmode%
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
			\vskip-.75ex\par
		}{}
	}%
	\let\do\@makeother\dospecials\catcode`\^^M\active%
	\iftoggle{skdoc@impl}{
		\frenchspacing\@vobeyspaces
	}{}
	\verbatim@start%
}{%
	\iftoggle{skdoc@impl}{\@esphack}{}%
}
\DeclareDocumentEnvironment{MacroCode}{m}{
	\iftoggle{skdoc@impl}{
		\vspace{.2\baselineskip}
		\par\noindent
	}{}
	\skdoc@verbatim{#1}
}{
	\endskdoc@verbatim
	\iftoggle{skdoc@impl}{
		\vspace{.5\baselineskip}
	}{}
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
\RequirePackage[babel]{microtype}
\RequirePackage{scrpage2,calc,shortvrb,url,hyperref,multicol,%
				hologo,marginnote,atbegshi}
\RequirePackage[nomain,xindy,numberedsection,order=letter,%
				sanitize={description=false,sort=false}]{glossaries}
\RequirePackage{ydoc-code} %reimplement?
\RequirePackage{ydoc-desc} %reimplement?
\RequirePackage{PTSerif,ascii}%,PTMono}
\RequirePackage[defaultsans,osfigures,scale=0.95]{opensans}
\AtBeginDocument{\MakeShortVerb{\|}}

% Colors! (and fonts)
\RenewDocumentCommand\descfont{}{\sffamily\fontseries{sb}}
\RenewDocumentCommand\sectfont{}{\sffamily\fontseries{sb}}
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
\RenewDocumentCommand\pkg{m}{\textsf{#1}}
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
\DeclareDocumentEnvironment{macro}{smo}{%
	\@bsphack
	\index@macro*{#2}
	\@macroname{#2}%
	\IfBooleanTF{#1}{}{
		\PrintMacroImpl{#2}
		\IfNoValueTF{#3}{
			\macro@impl@argline@noarg{(no~arguments)}
		}{\macro@impl@args[#3]}
	}%
}{
	\let\skdoc@macroname@key\@empty
	\@esphack
}
\DeclareDocumentEnvironment{macro*}{mo}%
	{\begin{macro}*{#1}[#2]}{\end{macro}}
\DeclareDocumentEnvironment{environment}{smo}{%
	\@bsphack
	\index@environment*{#2}
	\@environmentname{#2}%
	\IfBooleanTF{#1}{}{
		\PrintEnvImplName{#2}
		\IfNoValueTF{#3}{
			\macro@impl@argline@noarg{(no~arguments)}
		}{\macro@impl@args[#3]}
	}%
}{
	\let\skdoc@macroname@key\@empty
	\@esphack
}
\DeclareDocumentEnvironment{environment*}{mo}%
	{\begin{environment}*{#1}[#2]}{\end{environment}}
\def\Describe@Macro#1{%
	\endgroup
	\edef\name{\expandafter\@gobble\string#1}%
	\global\@namedef{href@desc@\name}{}%
	\immediate\write\@mainaux{%
		\global\noexpand\@namedef{href@desc@\name}{}%
	}%
	\hbox\y@bgroup
	\@ifundefined{href@impl@\name}{}{\hyperlink{impl:\name}}%
	{%
		\hbox{
			\vbox to 0pt{
				\vss\hbox{
					\raisebox{4ex}{\hypertarget{desc:\name}{}
				}
			}
		}%
		\marginnote{\llap{\PrintMacroName{#1}}}
		}%
	}%
	\ydoc@macrocatcodes
	\macroargsstyle
	\read@Macro@arg
}
\def\descframe#1{%
    \mbox{\hspace*{1.5\descsep}#1\hspace*{2\descsep}}%
}
\def\PrintEnvImplName#1{%
	\par\mbox{}
	\marginnote{\llap{\implstyle{#1}}}
	\par
}
\def\macro@impl@argline@noarg#1{%
	\vspace*{-\baselineskip}
	\par\noindent{#1\strut}\par\medskip%
}
\def\macro@impl@argline#1#2{%
	\par\noindent{\texttt{\##1}:~#2\strut}%
}
\def\macro@impl@args[#1]{%
	\vspace*{-\baselineskip}
	\begingroup
	\let\macro@impl@argcnt\@tempcnta
	\let\macro@impl@curarg\@tempcntb
	\macro@impl@argcnt=#1\relax
	\macro@impl@curarg=0\relax
	\ifnum\macro@impl@curarg<\macro@impl@argcnt\relax
		\expandafter\macro@impl@arg
	\else
		\expandafter\macro@impl@endargs
	\fi
}
\def\macro@impl@endargs{
	\endgroup\par
}
\def\PrintMacroImpl#1{%
	\par
	\hbox{%
		\edef\name{\expandafter\@gobble\string#1}%
		\global\@namedef{href@impl@\name}{}%
		\immediate\write\@mainaux{%
			\global\noexpand\@namedef{href@impl@\name}{}%
		}%
		\raisebox{4ex}[4ex]{\hypertarget{impl:\name}{}}%
		\@ifundefined{href@desc@\name}{}{\hyperlink{desc:\name}}%
		\marginnote{\llap{\PrintMacroImplName{#1}}}%
	}%
	\par
}

%% And adding a few of our own
\DeclareDocumentCommand\opt{m}{\texttt{#1}}
\DeclareDocumentCommand\bib{m}{\texttt{@#1}}
\DeclareDocumentCommand\thm{m}{\textrm{#1}}
\DeclareDocumentCommand\@optionname{m}{
	\def\skdoc@macroname@stylized{\opt{\string#1}}
	\def\skdoc@macroname@key{opt-#1}
}
\DeclareDocumentCommand\@bibentryname{m}{
	\def\skdoc@macroname@stylized{\bib{\expandafter\@gobble\string#1}}
	\def\skdoc@macroname@key{bibentry-\expandafter\@gobble\string#1}
}
\DeclareDocumentCommand\@themename{m}{
	\def\skdoc@macroname@stylized{\thm{\string#1}}
	\def\skdoc@macroname@key{thm-#1}
}
\DeclareDocumentEnvironment{option}{sm}{%
	\@bsphack
	\index@option*{#2}
	\@optionname{#2}%
	\IfBooleanTF{#1}{}{
		\PrintEnvImplName{#2}
		\macro@impl@argline@noarg{(option)}
	}%
}{
	\let\skdoc@macroname@key\@empty
	\@esphack
}
\DeclareDocumentEnvironment{option*}{m}%
	{\begin{option}*{#1}}{\end{option}}
\DeclareDocumentEnvironment{bibentry}{sm}{%
	\@bsphack
	\index@bibentry*{#2}
	\@bibentryname{#2}%
	\IfBooleanTF{#1}{}{
		\PrintEnvImplName{#2}
		\macro@impl@argline@noarg{(\hologoRobust{BibTeX}~entry~type)}
	}%
}{
	\let\skdoc@macroname@key\@empty
	\@esphack
}
\DeclareDocumentEnvironment{bibentry*}{m}%
	{\begin{bibentry}*{#1}}{\end{bibentry}}
\DeclareDocumentEnvironment{theme}{sm}{%
	\@bsphack
	\index@theme*{#2}
	\@themename{#2}%
	\IfBooleanTF{#1}{}{
		\PrintEnvImplName{#2}
		\macro@impl@argline@noarg{(theme)}
	}%
}{
	\let\skdoc@macroname@key\@empty
	\@esphack
}
\DeclareDocumentEnvironment{theme*}{m}%
	{\begin{theme}*{#1}}{\end{theme}}
\let\optpar\relax
%\def\skdoc@Options@peek{
%	\ifx\@let@token\WithValues\llap{\texttt{=}}\else\fi
%}
\DeclareDocumentCommand\Options{m}{
	\clist_set:Nn\l_tmpa_clist{#1}
	\marginnote{
		\clist_map_inline:Nn\l_tmpa_clist{
			\index@option{####1}
			\hfill
			\llap{\textcolor{opt}{\opt{####1}}}
			\mbox{}\\
		}
	}
	\nobreak
%	\futurelet\@let@token\skdoc@Options@peek
}
\DeclareDocumentCommand\Option{m}{
	\Options{#1}
}
\def\skdoc@WithValues@peek{
	\ifx\@let@token\AndDefault\else\par\nobreak\fi
}
\DeclareDocumentCommand\WithValues{m}{
	\noindent\makebox[\linewidth][l]{\texttt{\textcolor{gray}{#1}}}
	\futurelet\@let@token\skdoc@WithValues@peek
}
\DeclareDocumentCommand\AndDefault{m}{
	\llap{\textcolor{gray}{\texttt{(#1)}}}\par\nobreak
}
\reversemarginpar

%% The usual documentation stuff (not all of it)
\newglossary{changes}{gls}{glo}{Changes}
\newglossarystyle{changelog}{
	\glossarystyle{altlist}
	\renewenvironment{theglossary}{
		\begin{multicols}{2}\begin{description}
%		\begin{minipage}{\linewidth}
	}{
%		\end{minipage}
		\end{description}\end{multicols}
	}
	\renewcommand*{\glossaryentryfield}[5]{
%		\end{minipage}
		\par\vspace{5\p@}\relax
%		\begin{minipage}{\linewidth}
		\item[\glsentryitem{##1}\glstarget{##1}{##2}]
					\mbox{}\par\nobreak\@afterheading
	}
	\renewcommand{\glossarysubentryfield}[6]{%
		\par\hspace*{\itemindent}
		\glssubentryitem{##2}%
		\glstarget{##2}{\strut}##4\glspostdescription\space ##6
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
			sort={0},
			nonumberlist=true
		}
		\glsadd[types=changes]{#1-general}
	\else
		\newglossaryentry{#1-\skdoc@macroname@key}{
			type=changes,
			description={\skdoc@macroname@stylized{}:~#2},
			parent={#1},
			sort={\skdoc@macroname@key},
			nonumberlist=true
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
	\renewenvironment{theglossary}{
		\begin{multicols}{2}
		\setlength{\parindent}{0pt}
		\setlength{\parskip}{0pt plus 0.3pt}
		\let\item\@idxitem
%		\begin{minipage}{\linewidth}
	}{
%		\end{minipage}
		\end{multicols}
	}
	\renewcommand*{\glossaryentryfield}[5]{
		\item\glsentryitem{##1}\glstarget{##1}{##2}
			\ifx\relax##4\relax\else\space(##4)\fi
			##3\glspostdescription\space ##5}
	\renewcommand*{\glsgroupheading}[1]{
		\item{\descfont\glsgetgrouptitle{##1}}%\indexspace
	}
	\renewcommand*{\glsgroupskip}{
%		\end{minipage}
		\par\vspace{15\p@}\relax
%		\begin{minipage}{\linewidth}
	}
}
\DeclareDocumentCommand\@index@{mm}{
	\iftoggle{skdoc@impl}{
		\@index@@{#1}{#2}
	}{
		\iftoggle{skdoc@in@impl}{}{
			\@index@@{#1}{#2}
		}
	}
}
\DeclareDocumentCommand\@index@@{mm}{
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
\DeclareDocumentCommand\index@macro{sm}{
	\def\skdoc@temp{\expandafter\@gobble\string#2}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\expandafter\@gobble\string#2}
				{\cs{\expandafter\@gobble\string#2}}
	}
	\IfBooleanTF{#1}{
		\glsadd[types=index]{index-\skdoc@temp}
	}{
		\glsadd[types=index,format=hyperit]{index-\skdoc@temp}
	}
}
\let\old@PrintEnvName\PrintEnvName
\def\PrintEnvName#1#2{
	\ifx#1\begin
		\edef\skdoc@temp{\noexpand\index@environment{#2}}
		\skdoc@temp
	\fi
	\old@PrintEnvName{#1}{#2}
}
\DeclareDocumentCommand\index@environment{sm}{
	\def\skdoc@temp{\string#2}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\string#2}
				{\env{\string#2}~(environment)}
	}
	\IfBooleanTF{#1}{
		\glsadd[types=index]{index-\skdoc@temp}
	}{
		\glsadd[types=index,format=hyperit]{index-\skdoc@temp}
	}
}
\DeclareDocumentCommand\index@option{sm}{
	\def\skdoc@temp{\string#2}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\string#2}
				{\opt{\string#2}~(option)}
	}
	\IfBooleanTF{#1}{
		\glsadd[types=index]{index-\skdoc@temp}
	}{
		\glsadd[types=index,format=hyperit]{index-\skdoc@temp}
	}
}
\DeclareDocumentCommand\index@bibentry{sm}{
	\def\skdoc@temp{\expandafter\@gobble\string#2}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\expandafter\@gobble\string#2}
				{\bib{\expandafter\@gobble\string#2}~(\hologoRobust{BibTeX}~entry~type)}
	}
	\IfBooleanTF{#1}{
		\glsadd[types=index]{index-\skdoc@temp}
	}{
		\glsadd[types=index,format=hyperit]{index-\skdoc@temp}
	}
}
\DeclareDocumentCommand\index@theme{sm}{
	\def\skdoc@temp{\string#2}
	\ifglsentryexists{index-\skdoc@temp}{}{
		\@index@{\string#2}
				{\thm{\string#2}~(theme)}
	}
	\IfBooleanTF{#1}{
		\glsadd[types=index]{index-\skdoc@temp}
	}{
		\glsadd[types=index,format=hyperit]{index-\skdoc@temp}
	}
}
\providecommand*\PrintIndex{%
	\begingroup
	\renewcommand*{\glossarypreamble}{
		Numbers~written~in~italic~refer~to~the~page~where~the~corresponding~entry~is~described;~numbers~in~roman~refer~to~the~code~line~of~the~definition.\par
	}
	\printglossary[type=index,style=docindex]
	\endgroup
}

%% Hiding the implementation
% Consequence of method: last page before implementation is broken,
% anything after that is typeset on a new page.
\newtoggle{skdoc@impl}
\newtoggle{skdoc@in@impl}
\toggletrue{skdoc@impl}
\togglefalse{skdoc@in@impl}
\newcounter{skdoc@impl@page}
\AtBeginShipout{
	\iftoggle{skdoc@impl}{}{
		\iftoggle{skdoc@in@impl}{\AtBeginShipoutDiscard}{}
	}
}
\DeclareDocumentCommand\OnlyDescription{}{\togglefalse{skdoc@impl}}
\DeclareDocumentCommand\Implementation{}{
	\iftoggle{skdoc@impl}{}{
		\clearpage
		\toggletrue{skdoc@in@impl}
		\let\skdoc@old@part\part
		\DeclareDocumentCommand\part{som}{}
		\let\skdoc@old@section\section
		\DeclareDocumentCommand\section{som}{}
		\let\skdoc@old@subsection\subsection
		\DeclareDocumentCommand\subsection{som}{}
		\let\skdoc@old@subsubsection\subsubsection
		\DeclareDocumentCommand\subsubsection{som}{}
		\let\skdoc@old@paragraph\paragraph
		\DeclareDocumentCommand\paragraph{som}{}
		\let\skdoc@old@subparagraph\subparagraph
		\DeclareDocumentCommand\subparagraph{som}{}
		\setcounter{skdoc@impl@page}{\value{page}}
	}
}
\DeclareDocumentCommand\Finale{}{
	\iftoggle{skdoc@impl}{}{
		\clearpage
		\togglefalse{skdoc@in@impl}
		\let\part\skdoc@old@part
		\let\section\skdoc@old@section
		\let\subsection\skdoc@old@subsection
		\let\subsubsection\skdoc@old@subsubsection
		\let\paragraph\skdoc@old@paragraph
		\let\subparagraph\skdoc@old@subparagraph
		\setcounter{page}{\value{skdoc@impl@page}}
	}
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
	\title{The~\textsf{\textbf{\@package}}~package}%
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
\package[ctan]{\jobname}
% Default metadata
\let\@ctan\@empty%
\let\@repository\@empty%
\let\@plainemail\@empty%
\let\@email\@empty%
\let\@version\@empty%
\package{\jobname}
% Reading the metadata
\DeclareDocumentCommand\theversion{}{v\@version}
\DeclareDocumentCommand\thepackage{}{\pkg{\@package}}

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
	\setlength{\skdoc@abstract@aw}{\the\textwidth-\the\skdoc@abstract@tw-2em}%
	\begin{minipage}{\textwidth}
		\begin{minipage}[t]{\skdoc@abstract@tw}%
			\begin{flushright}%
				\leavevmode\descfont\abstractname%
			\end{flushright}%
		\end{minipage}%
		\hspace{1em}%
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

% And the TOC
\addtokomafont{sectionentry}{\rmfamily\bfseries}
\addtokomafont{sectionentrypagenumber}{\rmfamily\bfseries}
\let\l@section@\l@section
\def\l@section{\vskip -.75ex\l@section@}
\def\l@subsection{\vskip.35ex\penalty\@secpenalty\@dottedtocline{2}{1.5em}{2.7em}}
\def\l@subsubsection#1#2{
	\leftskip 4.2em
	\parindent 0pt
	{\let\numberline\@gobble{\small #1~[#2]}}
}
\def\l@table{\@dottedtocline{1}{0pt}{1.5em}}
\def\l@figure{\@dottedtocline{1}{0pt}{1.5em}}
\def\@pnumwidth{1.7em}
\AtEndDocument{\addtocontents{toc}{\par}}
\let\old@tableofcontents\tableofcontents
\DeclareDocumentCommand\tableofcontents{}{
	\microtypesetup{protrusion=false}
	\old@tableofcontents
	\microtypesetup{protrusion=true}
}

% And section headers
\renewcommand*{\othersectionlevelsformat}[1]{%
	\makebox[0pt][r]{%
	\fontfamily{fos}\mdseries\selectfont
	\csname the#1\endcsname\enskip}%
}

% Set up microtype properly
\g@addto@macro\@verbatim{\microtypesetup{activate=false}}
\microtypesetup{expansion,kerning,spacing,tracking}
\DisableLigatures{family = tt*}
