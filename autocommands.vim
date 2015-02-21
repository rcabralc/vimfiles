autocmd!

" Move between logical lines rather than physical lines on wrap mode.
function! <SID>add_line_motions()
    if &ft == 'qf'
        silent! nunmap j
        silent! nunmap k
    else
        nnoremap <buffer> j gj
        nnoremap <buffer> k gk
    endif
endfunction

" Highlight cursor line and column
set cursorline cursorcolumn
augroup Misc
    autocmd WinLeave * set nocursorline nocursorcolumn
    autocmd WinEnter * set cursorline cursorcolumn
    autocmd FileType * call <SID>add_line_motions()
augroup END

autocmd BufNewFile,BufRead *.txt setfiletype human
autocmd FileType mail,human,rst,gitcommit setlocal flp=^\s*\(\d\+\\|[a-z]\)[\].)]\s*
" " Git commits wrapped in 72 columns, so we can have four columns at left for
" " indentation (as git log does) and four columns at right (for symmetry) and
" " still have all the message fit in a 80-columns terminal.
autocmd FileType mail,human,gitcommit setlocal tw=72
autocmd FileType markdown,rst,human,mail,gitcommit setlocal ai fo=tcroqn tw=78 et sw=2 ts=2 sts=2
autocmd FileType yaml setlocal et ts=2 sw=2 sts=2 tw=79


" Change identation keys.  The automatic indent when <Return> is used in any
" place of the line is really crappy.
" autocmd FileType svg,xhtml,html,xml setlocal indentkeys=o,O,<>>,{,}
autocmd FileType svg,xhtml,html,xml setlocal fo+=tl tw=79 ts=2 sw=2 sts=2 et

autocmd FileType svg,xhtml,html,xml imap <buffer> <Leader>xc </<c-x><c-o><esc>a
autocmd FileType svg,xhtml,html,xml imap <buffer> <Leader>Xc </<c-x><c-o><esc>F<i

" Syntax highlighting for doctest
autocmd FileType rst setlocal syntax=doctest

" CSS
" Treat CMF's CSS files (actually DTML methods) as CSS files, as well KSS
" files.
autocmd BufNewFile,BufRead *.css.dtml,*.kss setfiletype css
autocmd BufRead,BufNewFile *.scss set filetype=scss
autocmd FileType css,scss,sass setlocal autoindent tw=79 ts=2 sts=2 sw=2 et

" JavaScript/Coffee
autocmd FileType javascript setlocal autoindent tw=79 ts=2 sts=2 sw=2 et
autocmd FileType coffee setlocal autoindent tw=79 ts=4 sts=4 sw=4 et

" Python
" Default python identation, as recommended by PEP8.
autocmd FileType python setlocal tw=79 et ts=4 sw=4 sts=4

" Ruby
autocmd FileType ruby setlocal et ts=2 sw=2 sts=2 tw=79
autocmd FileType eruby setlocal et ts=2 sw=2 sts=2 tw=79
" autocmd FileType eruby setlocal indentkeys=o,O,<Return>,<>>,{,},0),0],o,O,!^F,=end,=else,=elsif,=rescue,=ensure,=when,=end,=else,=cat,=fina,=END,0\

" Recognize Zope's controller python scripts and validators as python.
autocmd BufNewFile,BufRead *.cpy,*.vpy setfiletype python
" Treat Zope3's zcml files as xml, because actually they're it.
autocmd BufNewFile,BufRead *.zcml set ft=xml
autocmd BufNewFile,BufRead *.pt,*.cpt set ft=xml

autocmd FileType vim setlocal tw=79 sw=4 ts=4 sts=4 et

autocmd FileType c,cpp,slang setlocal cindent
autocmd FileType c setlocal fo+=ro

autocmd FileType snippet setlocal noexpandtab sw=2 ts=2

autocmd FileType fish compiler fish


" Highlight words to avoid in tech writing
" =======================================
"
" obviously, basically, simply, of course, clearly,
" just, everyone knows, However, So, easy

" http://css-tricks.com/words-avoid-educational-writing/

highlight! TechWordsToAvoid guisp=#ff6000 gui=undercurl
function! MatchTechWordsToAvoid()
  match TechWordsToAvoid /\c\<\(obviously\|basically\|simply\|of\scourse\|clearly\|just\|everyone\sknows\|however\|so,\|easy\)\>/
endfunction

augroup Misc
    autocmd FileType markdown,rst,human call MatchTechWordsToAvoid()
    autocmd BufWinEnter *.md,*.rst,*.human call MatchTechWordsToAvoid()
    autocmd InsertEnter *.md,*.rst,*.human call MatchTechWordsToAvoid()
    autocmd InsertLeave *.md,*.rst,*.human call MatchTechWordsToAvoid()
    autocmd BufWinLeave *.md,*.rst,*.human call clearmatches()

    " Make text wrap.
    autocmd FileType qf setlocal wrap
augroup END
