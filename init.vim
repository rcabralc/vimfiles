" vim et sw=4

if !has('nvim')
    set nocompatible " Be iMproved
endif

execute 'source ' . fnamemodify($MYVIMRC, ':p:h') . '/utils.vim'
call utils.vimsource('fuzzyfinder.vim')
call utils.vimsource('git.vim')
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

augroup Text
    autocmd!
    autocmd BufNewFile,BufRead *.txt setfiletype human

    " Git commits wrapped in 72 columns, so we can have four columns at left
    " for indentation (as git log does) and four columns at right (for
    " symmetry) and still have all the message fit in a 80-columns terminal.
    autocmd FileType mail,human,gitcommit setlocal tw=72
    autocmd FileType markdown,rst setlocal tw=78

    autocmd FileType markdown,rst,human,mail,gitcommit setlocal ai ts=2
    autocmd FileType yaml setlocal ts=2 tw=79

    " Make text wrap.
    autocmd FileType qf setlocal wrap
augroup END

augroup Prog
    autocmd!
    autocmd FileType ruby,html,eruby,javascript,coffee,css,scss,sass set ts=2 indentkeys-=*<Return>
    autocmd FileType python,vim set ts=4
    autocmd FileType ruby setlocal tags+=.git/rbtags
    autocmd BufWritePost *_spec.rb set syntax=rspec
    autocmd BufEnter *.arb setfiletype ruby
augroup END


" Highlighting optimizations
" ==========================

function! s:improve_highlights(p)
    hi! link cssClassName Type
    hi! link cssFunctionName Function
    hi! link cssIdentifier Identifier

    hi! link rubyPseudoVariable Identifier

    hi! link erubyDelimiter Delimiter

    hi! link xmlEndTag xmlTag

    hi! link vimUserFunc Function

    hi! link javascriptClassKeyword Define
    hi! link javascriptObjectLabel Identifier

    exe "hi! GitGutterAdd guibg=".a:p.term17." guifg="a:p.term10." gui=bold"
    exe "hi! GitGutterChange guibg=".a:p.term17." guifg="a:p.term11." gui=bold"
    exe "hi! GitGutterDelete guibg=".a:p.term17." guifg="a:p.term9." gui=bold"
    exe "hi! GitGutterChangeDelete guibg=".a:p.term17." guifg="a:p.term9." gui=bold"

    exe "hi! InsertModeStatus guibg=".a:p.term10." guifg="a:p.term0
    exe "hi! VisualModeStatus guibg=".a:p.term12." guifg="a:p.term0
    exe "hi! ReplaceModeStatus guibg=".a:p.term13." guifg="a:p.term0
    exe "hi! GitBranchStatus guibg=".a:p.term17." guifg="a:p.term12
    exe "hi! ModifiedStatus guibg=".a:p.term17." guifg="a:p.term13
    exe "hi! ReadonlyStatus guibg=".a:p.term17." guifg="a:p.term9
    exe "hi! WarningStatus guibg=".a:p.term9." guifg="a:p.term0
    exe "hi! FiletypeStatus guibg=".a:p.term17." guifg="a:p.term12
    exe "hi! AdditionalInfoStatus guibg=".a:p.term17." guifg="a:p.term19

    " Highligh intended to blend with vim-dimnactive
    if !has('nvim')
        exe "hi! NonText guibg=".a:p.term17." guifg="a:p.term8
    endif
endfunction

augroup Colors
    autocmd!
    autocmd ColorScheme undefined call s:improve_highlights(g:undefined#palette.current)
    autocmd ColorScheme * set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
augroup END

call utils.vimsource('pluginconf.vim')
call utils.vimsource('site.vim')

augroup CustomStatusLine
    autocmd!
    autocmd WinEnter * setlocal statusline=%!StatusLine(1)
    autocmd WinLeave * setlocal statusline=%!StatusLine(0)
augroup END

function! CustomALEStatus()
    let problems = ale#statusline#Count(bufnr('%'))['total']
    if problems > 0
        return ' '.problems.'(!)'
    else
        return ''
    endif
endfunction

function! StatusLine(active)
    let sections = [
        \ { 'val': a:active && mode() ==# 'i' ? ' INS ' : '', 'hl': 'InsertModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 't' ? ' TER ' : '', 'hl': 'InsertModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 'v' ? ' VIS ' : '', 'hl': 'VisualModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 'V' ? ' LVI ' : '', 'hl': 'VisualModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 's' ? ' SEL ' : '', 'hl': 'VisualModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 'S' ? ' LSE ' : '', 'hl': 'VisualModeStatus', 'pad': '' },
        \ { 'val': a:active && mode() ==# 'R' ? ' REP ' : '', 'hl': 'ReplaceModeStatus', 'pad': '' },
        \ { 'expr': '%m', 'hl': 'ModifiedStatus', 'enabled': mode() !=# 't' },
        \ { 'val': mode() ==# 't' ? getbufvar('%', 'term_title').' ['.getbufvar('%', 'terminal_job_pid').'] ' : '' },
        \ { 'expr': '%f', 'enabled': mode() !=# 't' },
        \ { 'expr': '%{fugitive#head(10)}', 'hl': 'GitBranchStatus', 'pad': '@', 'enabled': mode() !=# 't' },
        \ { 'expr': '%r', 'hl': 'ReadonlyStatus' },
        \ { 'expr': "%{CustomALEStatus()}", 'hl': 'WarningStatus' },
        \ { 'expr': '%l(%p%%)/%L:%c%V', 'hl': 'AdditionalInfoStatus' },
        \ { 'expr': '%y', 'hl': 'FiletypeStatus' },
        \ { 'expr': '%w' }
    \ ]
    let final_expr = ''
    for item in sections
        if has_key(item, 'enabled') && !item.enabled
            continue
        endif

        let expr = ''

        if has_key(item, 'val')
            if substitute(substitute(item.val, '^\s*', '', ''), '\s*$', '', '') != ''
                let expr = expr . substitute(item.val, '%', '%%', '')
            endif
        else
            let expr = item.expr
        endif

        if expr != ''
            " Custom padding is highlighted.
            let expr = (has_key(item, 'pad') ? item.pad : '') . expr

            if has_key(item, 'hl')
                if a:active
                    let expr = '%#' . item.hl . '#' . expr . '%*'
                else
                    let expr = '%#StatusLineNC#' . expr . '%*'
                endif
            endif

            " Default padding is not highlighted.
            let final_expr = final_expr . (has_key(item, 'pad') ? '' : ' ') . expr
        endif
    endfor

    return final_expr
endfunction

set statusline=%!StatusLine(1)
