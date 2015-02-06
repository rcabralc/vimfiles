" This seems more logical
nmap Y y$

" Toggle highlight for searched terms.
nmap <C-C> :set hlsearch!<CR>

" Navigate between buffers (only normal mode)
nnoremap <A-h> :bp<CR>
nnoremap <A-l> :bn<CR>

" <Leader>b prompts for displaying an open file in the current buffer
nnoremap <Leader>b :buffer<Space>

nnoremap <Leader>k :BW<CR>
nnoremap <Leader>K :bw!<CR>

" navigate between windows without pressing C-W
nnoremap <C-h> <C-W><C-h>
nnoremap <C-j> <C-W><C-j>
nnoremap <C-k> <C-W><C-k>
nnoremap <C-l> <C-W><C-l>

" Mappings for breaking lines on every white space or cursor
nnoremap <Leader>j f<Space>xi<CR><ESC>_
nnoremap <Leader>J F<Space>xi<CR><ESC>_
nnoremap <A-j> i<CR><ESC>_

" Mappings for breaking lines at 72 chars
nmap <Leader>w 073l<A-j>

" Search in current git tree.
nmap <C-S> :Ggrep -I  <bar> copen<CR>

" Just highlight pattern under cursor (hlsearch must be on).
nmap <A-8> *<S-n>

nmap <Leader>r :OverCommandLine<CR>%s///gc
vnoremap <Leader>r :OverCommandLine<CR>s//gc

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

" Open URL under cursor.
nnoremap <Leader>o :silent !xdg-open <C-R>=escape("<C-R><C-F>", "#?&;\|%")<CR><CR>

" vim-gitgutter: enable/disable line hightlighting
nmap <Leader>H <Plug>GitGutterLineHighlightsToggle
" vim-gitgutter: next/previous hunks
nmap <Leader>[ <Plug>GitGutterPrevHunk
nmap <Leader>] <Plug>GitGutterNextHunk

nmap <Leader>n :call <SID>ToggleRelativeNumber()<CR>

" Load a session in the current directory.
map <F3> :so Session.vim<CR>
" Save the session in the current directory.
nmap <F2> :wa<Bar>mksession!<CR>

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

map <A-b> :call <SID>softmotion('b')<CR>
map <A-w> :call <SID>softmotion('w')<CR>
map <A-e> :call <SID>softmotion('e')<CR>


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
