" This seems more logical
nmap Y y$

nnoremap <Leader>k :BW<CR>
nnoremap <Leader>K :bw!<CR>
inoremap <C-a><C-a> <Esc>
if has('nvim')
    tnoremap <C-a><C-a> <C-\><C-n>
endif

" Navigation and splitting mappings

nnoremap <A-h> :tabp<CR>
nnoremap <A-l> :tabn<CR>

nnoremap <C-h> <C-W>h
nnoremap <C-j> <C-W>j
nnoremap <C-k> <C-W>k
nnoremap <C-l> <C-W>l

inoremap <C-h> <ESC><C-W>h
inoremap <C-j> <ESC><C-W>j
inoremap <C-k> <ESC><C-W>k
inoremap <C-l> <ESC><C-W>l

if has('nvim')
    tnoremap <C-h> <C-\><C-n><C-w>h
    tnoremap <C-j> <C-\><C-n><C-w>j
    tnoremap <C-k> <C-\><C-n><C-w>k
    tnoremap <C-l> <C-\><C-n><C-w>l

    tnoremap <A-h> <C-\><C-n>:tabp<CR>
    tnoremap <A-l> <C-\><C-n>:tabn<CR>

    " Due to a bug in Neovim (related to external lib), <C-h> will not work.
    " This is a workaround.
    " tnoremap <C-w><BS> <C-\><C-n><C-W>h
    " inoremap <C-w><BS> <ESC><C-W>h

    function! OpenTermInDir(dir)
        if a:dir !~ '^term://'
            execute "lcd " .  g:utils.project_root(a:dir)
        endif

        set nospell
        edit term://fish
        startinsert
    endfunction

    nnoremap <Leader>t :call OpenTermInDir(expand('%:p:h'))<CR>

    " This kinda mimics Tmux.
    nnoremap <C-a>s :split<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-a><C-s> :split<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-a>v :vsplit<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-a><C-v> :vsplit<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    tmap <C-a>s <C-\><C-n><C-a>s
    tmap <C-a><C-s> <C-\><C-n><C-a>s
    tmap <C-a>v <C-\><C-n><C-a>v
    tmap <C-a><C-v> <C-\><C-n><C-a>v

    " Split windows when in term mode just like normal
    tmap <C-w>s <C-\><C-n><C-w>s
    tmap <C-w><C-s> <C-\><C-n><C-w>s
    tmap <C-w>v <C-\><C-n><C-w>v
    tmap <C-w><C-v> <C-\><C-n><C-w>v
endif

" Mappings for breaking lines at 72 chars
nmap <Leader>w 073l<A-j>

" Search in current git tree.
nmap <C-S> <A-8>:Ggrep -I  <bar> copen

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
nmap <Leader>h <Plug>GitGutterLineHighlightsToggle
" vim-gitgutter: next/previous hunks
nmap <Leader>[ <Plug>GitGutterPrevHunk
nmap <Leader>] <Plug>GitGutterNextHunk

" Fuzzy file opening
map <Leader>f :call g:fuzzy.open('edit', expand('%:p:h'), 1, '')<CR>
map <Leader>p :call g:fuzzy.open('read', expand('%:p:h'), 0, '')<CR>
map <Leader>b :call g:fuzzy.reopen('e')<CR>
map <Leader>o :call g:fuzzy.openold('e')<CR>

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

map <F6> "+p
map <S-F6> "+P

imap <F6> <C-o>"+p
imap <S-F6> <C-o>"+P

map <A-b> :call <SID>softmotion('b')<CR>
map <A-w> :call <SID>softmotion('w')<CR>
map <A-e> :call <SID>softmotion('e')<CR>

function! <SID>softmotion(motion)
    let oldisk = &isk
    execute "setlocal isk=".substitute(oldisk, '_,', '', 'g')
    execute "normal ".a:motion
    execute "setlocal isk=".oldisk
endfunction

nmap <Leader>s :set hlsearch!<CR>
nmap <Leader>n :set relativenumber!<CR>
nmap <Leader>c :set cursorcolumn!<CR>
