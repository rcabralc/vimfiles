" This seems more logical
nmap Y y$

" Toggle highlight for searched terms.
nmap <C-C> :set hlsearch!<CR>

" Navigate between tabs (only normal mode)
nnoremap <A-h> :tabp<CR>
nnoremap <A-l> :tabn<CR>

nnoremap <Leader>k :BW<CR>
nnoremap <Leader>K :bw!<CR>

" navigate between windows without pressing C-W
if has('nvim')
    tnoremap <C-]> <C-\><C-n>

    nnoremap <C-h> <C-w>h
    nnoremap <C-j> <C-w>j
    nnoremap <C-k> <C-w>k
    nnoremap <C-l> <C-w>l

    " Due to a bug in NeoVim (related to external lib), <C-h> will not work.
    " This is a workaround.
    if has('nvim')
        nnoremap <BS> <C-W>h
    endif
else
    nnoremap <C-h> <C-W>h
    nnoremap <C-j> <C-W>j
    nnoremap <C-k> <C-W>k
    nnoremap <C-l> <C-W>l
endif

" Mappings for breaking lines at 72 chars
nmap <Leader>w 073l<A-j>

" Search in current git tree.
nmap <C-S> <A-8>:Ggrep -I  <bar> copen<CR>

" Just highlight pattern under cursor.
nmap <A-8> :set hlsearch<CR>*<S-n>

" Ensure highlight is on during searches
nnoremap / :set hlsearch<CR>/
nnoremap ? :set hlsearch<CR>?
nnoremap n :set hlsearch<CR>n
nnoremap <S-n> :set hlsearch<CR><S-n>

" For Emacs-style editing on the command-line:
" start of line
cnoremap <C-A> <Home>
" back one character
cnoremap <C-B> <Left>
" delete character under cursor
cnoremap <C-D> <Del>
" end of line
cnoremap <C-E> <End>
" forward one character
cnoremap <C-F> <Right>
" recall newer command-line
cnoremap <C-N> <Down>
" recall previous (older) command-line
cnoremap <C-P> <Up>
" back one word
cnoremap <Esc>b <S-Left>
" forward one word
cnoremap <Esc>f <S-Right>

" vim-gitgutter: enable/disable line hightlighting
nmap <Leader>H <Plug>GitGutterLineHighlightsToggle
" vim-gitgutter: next/previous hunks
nmap <Leader>[ <Plug>GitGutterPrevHunk
nmap <Leader>] <Plug>GitGutterNextHunk

nmap <C-n> :call <SID>ToggleRelativeNumber()<CR>

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

map <A-b> :call <SID>softmotion('b')<CR>
map <A-w> :call <SID>softmotion('w')<CR>
map <A-e> :call <SID>softmotion('e')<CR>

map <F6> "+p
map <S-F6> "+P

imap <F6> <C-o>"+p
imap <S-F6> <C-o>"+P

function! s:ToggleRelativeNumber()
    if &relativenumber
        set norelativenumber
    else
        set relativenumber
    endif
endfunction

function! <SID>softmotion(motion)
    let oldisk = &isk
    execute "setlocal isk=".substitute(oldisk, '_,', '', 'g')
    execute "normal ".a:motion
    execute "setlocal isk=".oldisk
endfunction
