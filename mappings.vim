let mapleader = "\<Space>"

map <C-c> <Esc>
cmap <C-c> <Esc>
imap <C-c> <Esc>

" This seems more logical
nmap Y y$

" Navigation and splitting mappings

nnoremap <A-C-h> :tabp<CR>
nnoremap <A-C-l> :tabn<CR>

noremap L :bn<CR>
noremap H :bp<CR>

nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
inoremap <A-h> <Esc><C-w>h
inoremap <A-j> <Esc><C-w>j
inoremap <A-k> <Esc><C-w>k
inoremap <A-l> <Esc><C-w>l

if has('nvim')
    tnoremap <C-b><C-b> <C-b>
    tnoremap <C-b><C-c> <C-\><C-n>
    tnoremap <C-b><Esc> <C-\><C-n>

    tnoremap <A-h> <C-\><C-n><C-w>h
    tnoremap <A-j> <C-\><C-n><C-w>j
    tnoremap <A-k> <C-\><C-n><C-w>k
    tnoremap <A-l> <C-\><C-n><C-w>l

    tnoremap <A-C-h> <C-\><C-n>:tabp<CR>
    tnoremap <A-C-l> <C-\><C-n>:tabn<CR>

    tnoremap <C-r><C-r> <C-r>
    tnoremap <expr> <C-r><Esc> '<C-\><C-N>"'.nr2char(getchar()).'pi'

    function! OpenTermInDir(dir)
        if a:dir !~ '^term://'
            execute "lcd " .  g:utils.project_root(a:dir)
        endif

        set nospell
        edit term://fish
        setlocal nonumber
        startinsert
    endfunction

    nnoremap <Leader><CR> :call OpenTermInDir(expand('%:p:h'))<CR>

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
map <Leader>ff :call g:fuzzy.open('edit', expand('%:p:h'))<CR>
map <Leader>vf :call g:fuzzy.open('vsplit', expand('%:p:h'))<CR>
map <Leader>sf :call g:fuzzy.open('split', expand('%:p:h'))<CR>
map <Leader>tf :call g:fuzzy.open('tabedit', expand('%:p:h'))<CR>
map <Leader>FF :call g:fuzzy.open('edit', $HOME)<CR>
map <Leader>VF :call g:fuzzy.open('vsplit', $HOME)<CR>
map <Leader>SF :call g:fuzzy.open('split', $HOME)<CR>
map <Leader>TF :call g:fuzzy.open('tabedit', $HOME)<CR>
map <Leader>rf :call g:fuzzy.open('read', expand('%:p:h'))<CR>
map <Leader>bb :call g:fuzzy.reopen('edit')<CR>
map <Leader>vb :call g:fuzzy.reopen('vsplit')<CR>
map <Leader>sb :call g:fuzzy.reopen('split')<CR>
map <Leader>tb :call g:fuzzy.reopen('tabedit')<CR>
map <Leader>o :call g:fuzzy.openold('edit')<CR>
map <Leader>g :call g:fuzzy.open('edit', g:utils.rubygems_path(expand('%:p:h')))<CR>
map <A-C-b> :call g:fuzzy.open_from_branch()<CR>
map <A-C-c> :call g:gitcommand.checkout()<CR>

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

nmap <C-F> /

nnoremap <Leader>k :BW<CR>
nnoremap <Leader>K :bw!<CR>
nnoremap <Leader>q :q<CR>
nnoremap <Leader>w :w<CR>
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

" Command line history
cmap <C-p> <Up>
cmap <C-n> <Down>

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


" ALE
" ===

nmap <silent> <A-C-k> <Plug>(ale_previous_wrap)
nmap <silent> <A-C-j> <Plug>(ale_next_wrap)


" Git
" ===

function! s:stage_hunk_and_reload_status()
    :GitGutterStageHunk
    silent call fugitive#reload_status()
endfunction

function! s:undo_hunk_and_reload_status()
    :GitGutterUndoHunk
    silent call fugitive#reload_status()
endfunction

nmap <Leader>h <Plug>GitGutterLineHighlightsToggle
nmap <C-k> <Plug>GitGutterPrevHunk
nmap <C-j> <Plug>GitGutterNextHunk
nmap <C-s> :call <SID>stage_hunk_and_reload_status()<CR>
nmap <Leader>hu :call <SID>undo_hunk_and_reload_status()<CR>
nmap <Leader>G :Gst<CR>


" Incsearch and asterisk
" ======================

" Walk though quickfix lines.
map <A-C-n> :cn <bar> set hlsearch<CR>
map <A-C-p> :cp <bar> set hlsearch<CR>

" Search in current git tree. (* marks the word without jumping to next
" match thanks to vim-asterisk.)
nmap K *:F  .
vmap K y:F " .
nmap <A-s> :F  .<C-b><C-b>

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


" dadbod
" ======

map <Leader>db vip:DB<Space>$PGJENGAPRD<CR>
