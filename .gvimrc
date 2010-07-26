set guioptions-=m
set guioptions-=r
set guioptions-=L
set guioptions-=T
set guifont=Clean\ 9
set visualbell t_vb="

set guicursor=n:ver25-blinkon0-Cursor/lCursor,v-c:block-Cursor/lCursor,ve:ver35-Cursor,o:hor50-Cursor,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor,sm:block-Cursor-blinkwait175-blinkoff150-blinkon175

colorscheme railscasts

" Since in GUI version there's no terminal, I can define the same shortcut used
" to switch tabs in the terminal to switch buffers here.
map <A-h> :bp<Return>
map <A-l> :bn<Return>
