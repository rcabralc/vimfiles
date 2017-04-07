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

noremap <S-l> :bn<CR>
noremap <S-h> :bp<CR>

nnoremap <A-C-h> <C-W>h
nnoremap <A-C-j> <C-W>j
nnoremap <A-C-k> <C-W>k
nnoremap <A-C-l> <C-W>l

if has('nvim')
    tnoremap <A-C-h> <C-\><C-n><C-w>h
    tnoremap <A-C-j> <C-\><C-n><C-w>j
    tnoremap <A-C-k> <C-\><C-n><C-w>k
    tnoremap <A-C-l> <C-\><C-n><C-w>l

    tnoremap <A-h> <C-\><C-n>:tabp<CR>
    tnoremap <A-l> <C-\><C-n>:tabn<CR>

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
endif

" Mapping for breaking lines at 72 chars
nmap <Leader>w 073l<A-j>

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

" Fuzzy file opening
map <Leader>f :call g:fuzzy.open('edit', expand('%:p:h'), 1, '')<CR>
map <Leader>p :call g:fuzzy.open('read', expand('%:p:h'), 0, '')<CR>
map <Leader>b :call g:fuzzy.reopen('e')<CR>
map <Leader>o :call g:fuzzy.openold('e')<CR>
map <Leader>d :call g:fuzzy.select_dir('e', $HOME, expand('%:p:h'), 5)<CR>
map <Leader>g :call g:fuzzy.select_gem_dir('e', expand('%:p:h'))<CR>
map <A-b> :call g:fuzzy.open_from_branch()<CR>
map <A-c> :call g:gitcommand.checkout()<CR>

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

" map <A-b> :call <SID>softmotion('b')<CR>
" map <A-w> :call <SID>softmotion('w')<CR>
" map <A-e> :call <SID>softmotion('e')<CR>
"
" function! <SID>softmotion(motion)
"     let oldisk = &isk
"     let &isk = substitute(substitute(substitute(oldisk.',', '[-_],', '', 'g'), ',\+', ',', 'g'), ',$', '', '')
"     execute "normal ".a:motion
"     let &isk = oldisk
" endfunction

nmap <Leader>n :set relativenumber!<CR>
nmap <Leader>c :set cursorcolumn!<CR>

nmap <silent> <A-k> <Plug>(ale_previous_wrap)
nmap <silent> <A-j> <Plug>(ale_next_wrap)

nmap <Leader>h <Plug>GitGutterLineHighlightsToggle
nmap <C-k> <Plug>GitGutterPrevHunk
nmap <C-j> <Plug>GitGutterNextHunk
nmap <C-s> <Plug>GitGutterStageHunk

nmap Z :bw<CR>

" Incsearch and asterisk
" ======================

" Walk though quickfix lines.
map <A-n> :cn <bar> set hlsearch<CR>
map <A-p> :cp <bar> set hlsearch<CR>

" Search in current git tree. (* marks the word without jumping to next
" match thanks to vim-asterisk.)
nmap K *:Ggrep -I  <bar> copen

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl)<Plug>(asterisk-z*)
map #  <Plug>(incsearch-nohl)<Plug>(asterisk-z#)
map g* <Plug>(incsearch-nohl)<Plug>(asterisk-gz*)
map g# <Plug>(incsearch-nohl)<Plug>(asterisk-gz#)

map z/ <Plug>(incsearch-fuzzy-/)
map z? <Plug>(incsearch-fuzzy-?)
map zg/ <Plug>(incsearch-fuzzy-stay)
