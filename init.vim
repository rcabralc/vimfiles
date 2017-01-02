" vim et sw=4

if !has('nvim')
    set nocompatible " Be iMproved
endif

execute 'source ' . fnamemodify($MYVIMRC, ':p:h') . '/utils.vim'
call utils.vimsource('fuzzyfinder.vim')
call utils.vimsource('defaults.vim')
call utils.vimsource('plugins.vim')
call utils.vimsource('mappings.vim')

syntax enable
filetype plugin indent on

" Ctags for Git repos.  This requires .git/hooks/ctags available.  This can
" be achieved following Tim Pope instructions at
" http://tbaggery.com/2011/08/08/effortless-ctags-with-git.html
"
" Tags are stored in .git/tags, which is added to &tags by Fugitive.
map <C-F6> :RegenerateCTagsForGitRepo<CR>

function! s:regenerate_ctags_for_git_repo()
    let dir = g:utils.gitroot(expand('%'))
    echo dir
    if !empty(dir) && filereadable(dir.'/.git/hooks/ctags')
        exe '!cd '.dir.' && ./.git/hooks/ctags'
    else
        echo "Not available. Are you inside a Git repo with .git/hooks/ctags?"
    endif
endfunction

command! RegenerateCTagsForGitRepo call s:regenerate_ctags_for_git_repo()

set listchars=tab:»»,trail:•
set list

augroup Text
    autocmd!
    autocmd BufNewFile,BufRead *.txt setfiletype human

    " Git commits wrapped in 72 columns, so we can have four columns at left
    " for indentation (as git log does) and four columns at right (for
    " symmetry) and still have all the message fit in a 80-columns terminal.
    autocmd FileType mail,human,gitcommit setlocal tw=72
    autocmd FileType markdown,rst setlocal tw=78

    autocmd FileType markdown,rst,human,mail,gitcommit setlocal ai et sw=2 ts=2 sts=2
    autocmd FileType yaml setlocal et ts=2 sw=2 sts=2 tw=79

    " Make text wrap.
    autocmd FileType qf setlocal wrap
augroup END

augroup Prog
    autocmd!
    autocmd FileType ruby,html,eruby,javascript,coffee,css,scss,sass set ts=2 sw=2 sts=2 indentkeys-=*<Return>
    autocmd FileType python,vim set ts=4 sw=4 sts=4
augroup END


" Highlighting optimizations
" ==========================

function! s:improve_highlights(p)
    hi! link cssClassName Type
    hi! link cssFunctionName Function
    hi! link cssIdentifier Identifier

    hi! link rubyPseudoVariable Special

    hi! link erubyDelimiter Delimiter

    call rcabralc#hl('GitGutterAdd',           a:p.green,   a:p.none, 'bold')
    call rcabralc#hl('GitGutterChange',        a:p.cyan,    a:p.none, 'bold')
    call rcabralc#hl('GitGutterDelete',        a:p.magenta, a:p.none, 'bold')
    call rcabralc#hl('GitGutterChangeDelete',  a:p.magenta, a:p.none, 'bold')

    if !exists('g:indent_guides_auto_colors')
      let g:indent_guides_auto_colors = 0
    endif

    if g:indent_guides_auto_colors == 0
      call rcabralc#hl('IndentGuidesOdd',  a:p.none, a:p.gray0)
      call rcabralc#hl('IndentGuidesEven', a:p.none, a:p.gray1)
    endif
endfunction

augroup Colors
    autocmd!
    autocmd ColorScheme rcabralc call s:improve_highlights(g:rcabralc#palette)
augroup END

call utils.vimsource('pluginconf.vim')
