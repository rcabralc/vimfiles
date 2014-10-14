" vim et sw=4

set nocompatible " Be iMproved
set shell=/bin/sh " Avoid problems with fish shell

runtime! defaults.vim
runtime! plugins.vim
runtime! pluginconf.vim
runtime! autocommands.vim
runtime! mappings.vim

syntax enable

" Calculator using python
" =======================

if has('python3')
    command! -nargs=+ Calc :py3 print <args>
    py3 import math
elseif has('python')
    command! -nargs=+ Calc :py print <args>
    py import math
endif


" Highlighting optimizations
" ==========================

highlight! TrailingSpace ctermbg=red guibg=red
match TrailingSpace /\s\+$/

augroup Misc
    autocmd BufWinEnter * if &modifiable | match TrailingSpace /\s\+$/ | endif
    autocmd InsertEnter * if &modifiable | match TrailingSpace /\s\+\%#\@<!$/ | endif
    autocmd InsertLeave * if &modifiable | match TrailingSpace /\s\+$/ | endif
    autocmd BufWinLeave * if &modifiable | call clearmatches() | endif
augroup END


hi! link rubyBlockParameter Special
hi! link erubyDelimiter Operator

hi! link javaScriptFuncExp Normal
hi! link javaScriptGlobal Normal
" Strangely enough, these JS identifiers are actually keywords.
hi! link javaScriptIdentifier Keyword
" I don't care that these be not highlighted in a special way.
hi! link javaScriptHtmlElemProperties Normal

colorscheme monokai
