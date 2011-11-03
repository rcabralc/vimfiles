" vim et sw=4
" ===================
" Configuração padrão
" ===================

" Activate pathogen
call pathogen#infect()

" Interface
" =========

" Nocompatible mode
set nocompatible

" limpe qualquer autocommand existente
autocmd!

" permita que arquivos definam configuração
set modeline

" Highlight cursor line
set cursorline

" Highlight cursor column
set cursorcolumn

" Turn on command line completion wild style
set wildmenu

" Leave the cursor where it was
set nostartofline

" Keep some lines around for scope
set scrolloff=10

" permita uso do mouse em todos os modos
" set mouse=a

" exiba os números de linha
" set number

" tenha cinquenta linhas de histórico
set history=50

" always show the status line
set laststatus=2

" Lazy redraw
set lazyredraw

" fugitive indication
set statusline=%<%f\ %h%m%r%{fugitive#statusline()}%=%-14.(%l,%c%V%)\ %P

" have command-line completion <Tab> (for filenames, help topics, option names)
" first list the available options and complete the longest common part, then
" have further <Tab>s cycle through the possibilities:
set wildmode=list:longest,full

" display the current mode and partially-typed commands in the status line:
set showmode
set showcmd

" quebre linhas longas
set wrap

" permita que buffers sejam trocados sem perder as alterações
set hidden

" Colors
" ======

" configuração de cores para fundo escuro
" set bg=dark

" Set the number of colors to 256.  This requires a capable terminal.
set t_Co=256

" sintaxe colorida
syntax on

" default color scheme
" colorscheme neverness
" colorscheme vividchalk
" colorscheme railscasts
" colorscheme zmrok
" colorscheme textmate16
" colorscheme quagmire
" colorscheme blackboard
" colorscheme desert
if has('gui_running')
  let g:indent_guides_auto_colors = 0
  colorscheme rcabralc
else
  colorscheme jellybeans
endif

" Mark text width column.
set colorcolumn=+1

" Ruby-Debugger
" =============

map <Leader>D :Rdebugger<Space>
map <Leader>P :RdbCommand<Space>p<Space>
map <Leader>L :RdbLog<CR>
map <Leader>S :RdbStop<CR>

" Rails
" =====

map <Leader><C-m> :Rmodel<Space>
map <Leader><C-v> :Rview<Space>
map <Leader><C-o> :Rcontroller<Space>
map <Leader><C-h> :Rhelper<Space>
map <Leader><C-s> :Rspec<Space>
map <Leader><C-l> :Rlib<Space>


" Mappings
" ========

" Navigate between buffers (only normal mode)
nnoremap <C-N> :bn!<CR>
nnoremap <C-P> :bp!<CR>

" Navigate between tabs (overrides the default from, to match settings of
" Pentadactyl).
map <A-h> gT
map <A-j> gt

" <C-\> prompts for opening a buffer
nnoremap <C-\> :buffer<Space>

" E prompts for a new/edit file (in the current window)
nnoremap E :edit<Space>

" <Leader>K kills a buffer ignoring changes and closes the window, <Leader>k
" kills a buffer when there's no changes and preserves the window.
map <Leader>k :call KillBuffer()<CR>
function! KillBuffer()
    let del_buf_nr = bufnr("%")
    let new_buf_nr = bufnr("#")
    if ((new_buf_nr != -1) && (new_buf_nr != del_buf_nr) && buflisted(new_buf_nr))
        execute "b " . new_buf_nr
    else
        bnext
    endif
    if (bufnr("%") == del_buf_nr)
        new
    endif
    execute "bw " . del_buf_nr
endfunction
map <Leader>K :bw!<CR>

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

" Redraw screen, useful for when using small fonts which left some artifacts on
" the screen after subsequent edits.  Also reset the highlight of OverLength.
map <A-r> :redraw! <Bar> call MatchOverLength()<Return>

" Open URL under cursor.
nnoremap <Leader>o :silent !xdg-open <C-R>=escape("<C-R><C-F>", "#?&;\|%")<CR><CR>


" Text formatting
" ===============

" Make the Q key format the entire paragraph.  This makes the Ex mode go away,
" but I don't use that, and I can enter in Ex mode (in a way more like typing
" ":") by using gQ.
nnoremap Q gqap

" use indents of 4 spaces, and have them copied down lines:
set shiftwidth=4
set shiftround
set expandtab
set smarttab

" Text width at 79 chars allows me to easily split windows vertically.
set textwidth=79

" Ragtag plugin global mappings.
inoremap <M-o> <Esc>o
let g:ragtag_global_maps = 1

" Tipos de arquivos específicos
" =============================

" detecte os tipos de arquivo
filetype off
filetype plugin indent on

" geral
augroup general
  autocmd BufNewFile,BufRead *.txt set filetype=human
augroup END

augroup python
  " Recognize Zope's controller python scripts and validators as python.
  autocmd BufNewFile,BufRead *.cpy,*.vpy set filetype=python

  " Default python identation, as recommended by PEP8.
  autocmd FileType python set tw=79 et ts=4 sw=4 sts=4

  " Remove whitespace at the end of lines.
  autocmd BufWritePre *.py,*.cpy,*.vpy normal m`:%s/\s\*$//e ``

  " pylint
  autocmd FileType python compiler pylint
augroup END

augroup rest
  " formatação de commits do git segue mesmo padrão do rest

  " Some options for rest/gitcommit.
  autocmd FileType rst,gitcommit set ai fo=tcroqn tw=78 et sw=2 ts=2 sts=2

  " format list pattern
  autocmd FileType rst,gitcommit set flp=^\\s*\\(\\d\\+\\\|[a-z]\\)[\\].)]\\s*

  " Syntax highlighting for doctest
  autocmd FileType rst set syntax=doctest
augroup END

augroup css
  " Treat CMF's CSS files (actually DTML methods) as CSS files, as well KSS
  " files.
  autocmd BufNewFile,BufRead *.css.dtml,*.kss set filetype=css

  autocmd FileType css set smartindent autoindent tw=79 ts=2 sts=2 sw=2 et
augroup END

augroup js
  autocmd FileType javascript set smartindent autoindent tw=79 ts=2 sts=2 sw=2 et
augroup END

augroup ruby
  autocmd FileType ruby set et ts=2 sw=2 sts=2 tw=79
augroup END

augroup eruby
  autocmd FileType eruby set et ts=2 sw=2 sts=2 tw=79
  " Change identation keys.  The automatic indent when <Return> is used in any
  " place of the line is really crappy.
  autocmd FileType eruby setlocal indentkeys=o,O,<Return>,<>>,{,},0),0],o,O,!^F,=end,=else,=elsif,=rescue,=ensure,=when,=end,=else,=cat,=fina,=END,0\
augroup END

augroup sgml
  " Treat Zope3's zcml files as xml, because actually they're it.
  autocmd BufNewFile,BufRead *.zcml set ft=xml

  " Treat Zope's template files as xhtml, because the TAL implementation is
  " compatible with this.
  autocmd BufNewFile,BufRead *.pt,*.cpt set filetype=xhtml

  " autocmd FileType svg,xhtml,html,xml set nosmartindent
  " Change identation keys.  The automatic indent when <Return> is used in any
  " place of the line is really crappy.
  autocmd FileType svg,xhtml,html,xml setlocal indentkeys=o,O,<>>,{,}
  autocmd FileType svg,xhtml,html,xml set fo+=tl tw=79 ts=2 sw=2 sts=2 et
augroup END

augroup text
  autocmd FileType mail,human set fo+=t tw=72
augroup END

augroup vim
  autocmd FileType vim set tw=79
augroup END

augroup clike
  autocmd FileType c,cpp,slang set cindent
augroup END

augroup c
  autocmd FileType c set fo+=ro
augroup END

augroup snippet
  autocmd FileType snippet set noexpandtab sw=2 ts=2
augroup END


" Procura e substituição
" ======================

" case-insensitive, a menos que haja maiúsculas
set ignorecase
set smartcase

" incremental
set incsearch


" General settings
" ================

" Session management
" ==================

" When quitting, save the session.
autocmd! VimLeavePre * mksession!

" Load a session in the current directory.
map <Leader>l :so Session.vim<CR>

" More
" ====

" Calculator using python
" -----------------------
command! -nargs=+ Calc :py print <args>
py import math

" Syntastic configuration
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_auto_loc_list=1
let g:syntastic_enable_signs=1

" Disable syntastic for python, as I use pyflakes.
let g:syntastic_disabled_filetypes = ['python']

" Hilite trailing spaces as errors
autocmd Syntax * syntax match TrailingSpace "\s\+$" containedin=ALL
highlight link TrailingSpace Error

" Hilite excess in long lines as errors
function! MatchOverLength()
    if &colorcolumn =~ "^+"
        " Sum &tw value with &cc value.
        let column = eval(&textwidth.&colorcolumn)
    else
        if &colorcolumn != ''
            let column = &colorcolumn
        else
            let column = &textwidth
        endif
    endif
    execute "match OverLength /.\\%>".column."v/"
endfunction
highlight link OverLength Error
autocmd Syntax,WinEnter,WinLeave * call MatchOverLength()

let g:already_bored_with_overlength = 1

" Save the session and prompt for loading another.
nmap <F2> :wa<Bar>exe "mksession! " . v:this_session<CR>:so ~/vim-sessions/
