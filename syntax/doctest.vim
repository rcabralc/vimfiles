"
" ATTENTION: L'ordre est important pour la bonne résolution des instructions
"
runtime! syntax/rst.vim
unlet b:current_syntax

syn include @Python syntax/python.vim

syn match   doctestMarker   "^\s*>>>\|^\s*\.\.\." contained

syn region  doctestBloc
      \ start="::\_s*\n\ze\z\s*\.\.\."
      \ start="::\_s*\n\ze\z\s*>>>"
      \ start="^\s*\.\.\..*$"
      \ start="^\s*>>>.*$"
      \ end="^$"
      \ contains=doctestValue,doctestMarker,pythonTraceback,@Python

syn region  doctestValue start="^\s*[^.>]" end="$" contained

syn match pythonTraceback "Traceback\s*(most\s*recent\s*call\s*last)\s*:" contained


hi link doctestMarker     Special
hi link doctestValue      Constant
hi link pythonTraceback   Structure

hi link rstSections       Title
hi link rstTransition     Title

