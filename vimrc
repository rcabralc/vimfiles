" vim et sw=4

set nocompatible " Be iMproved
set shell=/bin/sh " Avoid problems with fish shell

runtime! defaults.vim
runtime! plugins.vim
runtime! pluginconf.vim
runtime! autocommands.vim
runtime! mappings.vim

syntax enable
filetype plugin indent on

" Calculator using python
" =======================

if has('python3')
    command! -nargs=+ Calc :py3 print <args>
    py3 import math
elseif has('python')
    command! -nargs=+ Calc :py print <args>
    py import math
endif

" Ctags for Git repos.  This requires .git/hooks/ctags available.  This can
" be achieved following Tim Pope instructions at
" http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html
map <C-F6> :RegenerateCTagsForGitRepo<CR>

function! s:regenerate_ctags_for_git_repo()
    if filereadable('.git/hooks/ctags')
        !.git/hooks/ctags
    else
        echo "Not available. Are you inside a Git repo with .git/hooks/ctags?"
    endif
endfunction

command! RegenerateCTagsForGitRepo call s:regenerate_ctags_for_git_repo()

colorscheme monokai

" Highlighting optimizations
" ==========================

hi! link rubyBlockParameter Special
hi! link erubyDelimiter Operator

hi! link javaScriptFuncExp Normal
hi! link javaScriptGlobal Normal
" Strangely enough, these JS identifiers are actually keywords.
hi! link javaScriptIdentifier Keyword
" I don't care that these be not highlighted in a special way.
hi! link javaScriptHtmlElemProperties Normal

autocmd BufWinEnter * if &modifiable | match TrailingSpace /\s\+$/ | endif
autocmd InsertEnter * if &modifiable | match TrailingSpace /\s\+\%#\@<!$/ | endif
autocmd InsertLeave * if &modifiable | match TrailingSpace /\s\+$/ | endif
autocmd BufWinLeave * if &modifiable | call clearmatches() | endif

highlight! TrailingSpace ctermbg=red guibg=red
match TrailingSpace /\s\+$/
