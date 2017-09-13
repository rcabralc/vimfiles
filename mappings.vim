let mapleader = "\<Space>"

" This seems more logical
nmap Y y$

" Navigation and splitting mappings

nnoremap <A-h> :tabp<CR>
nnoremap <A-l> :tabn<CR>

noremap <S-l> :bn<CR>
noremap <S-h> :bp<CR>

nmap <A-C-h> <C-w>h
nmap <A-C-j> <C-w>j
nmap <A-C-k> <C-w>k
nmap <A-C-l> <C-w>l

imap <A-C-h> <Esc><C-w>h
imap <A-C-j> <Esc><C-w>j
imap <A-C-k> <Esc><C-w>k
imap <A-C-l> <Esc><C-w>l

inoremap <A-C-h> <Esc><C-w>h
inoremap <A-C-j> <Esc><C-w>j
inoremap <A-C-k> <Esc><C-w>k
inoremap <A-C-l> <Esc><C-w>l

if has('nvim')
    tnoremap <C-b><C-b> <C-b>
    tnoremap <C-b><Esc> <C-\><C-n>

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
        setlocal nonumber
        startinsert
    endfunction

    nnoremap <Leader>t :call OpenTermInDir(expand('%:p:h'))<CR>

    nnoremap <C-b>s :split<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-b><C-s> :split<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-b>v :vsplit<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    nnoremap <C-b><C-v> :vsplit<CR>:call OpenTermInDir(expand('%:p:h'))<CR>
    tmap <C-b>s <C-\><C-n><C-b>s
    tmap <C-b><C-s> <C-\><C-n><C-b>s
    tmap <C-b>v <C-\><C-n><C-b>v
    tmap <C-b><C-v> <C-\><C-n><C-b>v
endif

" Fuzzy file opening
map <Leader>f :call g:fuzzy.edit(expand('%:p:h'))<CR>
map <Leader>F :call g:fuzzy.edit($HOME, '')<CR>
map <Leader>r :call g:fuzzy.read(expand('%:p:h'))<CR>
map <Leader>b :call g:fuzzy.reopen('e')<CR>
map <Leader>o :call g:fuzzy.openold('e')<CR>
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

nmap <silent> <A-k> <Plug>(ale_previous_wrap)
nmap <silent> <A-j> <Plug>(ale_next_wrap)

nmap <Leader>h <Plug>GitGutterLineHighlightsToggle
nmap <C-k> <Plug>GitGutterPrevHunk
nmap <C-j> <Plug>GitGutterNextHunk
nmap <C-s> <Plug>GitGutterStageHunk

nnoremap <Leader>k :BW<CR>
nnoremap <Leader>K :bw!<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>w :w<CR>
nmap <Leader>v V
map <Leader><Leader> :

" Copy and paste to and from system clipboard
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" Put visually-selected text into another register (_) before pasting content
" in visual mode.  This way text in default register (@) don't get replaced.
vnoremap p "_dP

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

" Expand region
" =============

map + <Plug>(expand_region_expand)
map - <Plug>(expand_region_shrink)
