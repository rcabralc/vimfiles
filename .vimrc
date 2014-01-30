" vim et sw=4
" ===================
" Configuração padrão
" ===================

set nocompatible " Be iMproved
" Plugins
" =======

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Activate NeoBundle
call neobundle#rc(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

" After install, turn shell ~/.vim/bundle/vimproc, (n,g)make -f your_machines_makefile
NeoBundle 'Shougo/vimproc'

NeoBundle 'vim-scripts/VST'
NeoBundle 'kien/ctrlp.vim'
NeoBundle 'editorconfig/editorconfig-vim'
NeoBundle 'nono/vim-handlebars'
NeoBundle 'othree/html5.vim'
NeoBundle 'tomasr/molokai'
NeoBundle 'Lokaltog/powerline', 'develop'
NeoBundle 'tomtom/quickfixsigns_vim'
NeoBundle 'cakebaker/scss-syntax.vim'
NeoBundle 'msanders/snipmate.vim'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'tomtom/tcomment_vim'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'hail2u/vim-css3-syntax'
NeoBundle 'tpope/vim-endwise'
NeoBundle 'tpope/vim-fugitive'
NeoBundle 'tpope/vim-git'
NeoBundle 'nathanaelkane/vim-indent-guides'
NeoBundle 'jelera/vim-javascript-syntax'
NeoBundle 'tsaleh/vim-matchit'
NeoBundle 'tpope/vim-rails'
NeoBundle 'tpope/vim-rake'
NeoBundle 'nvie/vim-rst-tables'
NeoBundle 'vim-ruby/vim-ruby'

NeoBundleCheck


" Interface
" =========

set number

set autoindent

" Smart indent is crap.
set nosmartindent

" Ensure backspace behavior is not alien.
set backspace=indent,eol,start

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

set history=50

" always show the status line
set laststatus=2

" Lazy redraw
set lazyredraw

" fugitive indication
set statusline=%{fugitive#statusline()}%*%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P

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

" Wrap search around the end of the file
set wrapscan

" Add powerline runtime path
set rtp+=~/.vim/bundle/powerline_develop/powerline/bindings/vim

" Mostly troublesome.
set nrformats-=octal

set shiftround

" Don't wait forever on key codes.
set ttimeout
set ttimeoutlen=50

set ignorecase
set smartcase
set incsearch

" Briefly jump to matching paren or bracket.  This is not milliseconds, but the
" docs don't say what it is.
set showmatch
set matchtime=3

filetype plugin indent on

" Use symbols in Powerline (requires capable font, both in terminal and in
" GUI).
let g:Powerline_symbols = 'fancy'


" Colors
" ======

" configuração de cores para fundo escuro
" set bg=dark

" Set the number of colors to 256.  This requires a capable terminal.
set t_Co=256

" sintaxe colorida
syntax on

let g:Powerline_colorscheme = 'default'
if has('gui_running')
  let g:molokai_original = 1
  colorscheme molokai

  " let g:indent_guides_auto_colors = 0
  " colorscheme rcabralc
else
  let g:molokai_original = 1
  let g:rehash256 = 1
  colorscheme molokai
endif

" Mark text width column.
set colorcolumn=+1


" Mappings
" ========

" Navigate between buffers (only normal mode)
map <A-h> :bp<Return>
map <A-l> :bn<Return>
nnoremap <A-S-l> :bn!<CR>
nnoremap <A-S-h> :bp!<CR>

" <C-\> prompts for displaying an open file in the current buffer
nnoremap <C-\> :buffer<Space>

" <Leader>K kills a buffer ignoring changes and closes the window, <Leader>k
" kills a buffer when there's no changes and preserves the window.
" map <Leader>k :call KillBuffer()<CR>
" function! KillBuffer()
"     let del_buf_nr = bufnr("%")
"     let new_buf_nr = bufnr("#")
"     if ((new_buf_nr != -1) && (new_buf_nr != del_buf_nr) && buflisted(new_buf_nr))
"         execute "b " . new_buf_nr
"     else
"         bnext
"     endif
"     if (bufnr("%") == del_buf_nr)
"         new
"     endif
"     execute "bw " . del_buf_nr
" endfunction
map <Leader>k :bw<CR>
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

" Search in current git tree.
nmap <C-S> :Ggrep  <bar> copen<CR>

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

" Python highlighting options.
let python_highlight_all = 1
let python_slow_sync = 1

" Python filetype options.
let g:python_syntax_fold = 0
let g:python_fold_strings = 0
let g:python_auto_complete_modules = 0
let g:python_auto_complete_variables = 0

" Ruby highlighting options
let g:ruby_operators = 1
let g:ruby_space_errors = 1
let g:ruby_no_trail_space_error = 1 " As we already have support for this for all filetypes


" Tipos de arquivos específicos
" =============================

" geral
augroup general
  autocmd BufNewFile,BufRead *.txt setfiletype human
augroup END

augroup python
  " Recognize Zope's controller python scripts and validators as python.
  autocmd BufNewFile,BufRead *.cpy,*.vpy setfiletype python

  " Default python identation, as recommended by PEP8.
  autocmd FileType python setlocal tw=79 et ts=4 sw=4 sts=4

  " Remove whitespace at the end of lines.
  autocmd BufWritePre *.py,*.cpy,*.vpy normal m`:%s/\s\*$//e ``
augroup END

augroup text
  " Some options for rest/gitcommit.
  autocmd FileType rst setlocal ai fo=tcroqn tw=78 et sw=2 ts=2 sts=2

  " " Git commits wrapped in 72 columns, so we can have four columns at left for
  " " indentation (as git log does) and four columns at right (for symmetry) and
  " " still have all the message fit in a 80-columns terminal.
  autocmd FileType gitcommit setlocal ai et sw=2 ts=2 sts=2

  " Syntax highlighting for doctest
  autocmd FileType rst setlocal syntax=doctest

  autocmd FileType mail,human setlocal fo+=t tw=72

  " format list pattern
  autocmd FileType mail,human,rst,gitcommit setlocal flp=^\s*\(\d\+\\|[a-z]\)[\].)]\s*
augroup END

augroup css
  " Treat CMF's CSS files (actually DTML methods) as CSS files, as well KSS
  " files.
  autocmd BufNewFile,BufRead *.css.dtml,*.kss setfiletype css
  autocmd BufRead,BufNewFile *.scss set filetype=scss

  autocmd FileType css,scss,sass setlocal autoindent tw=79 ts=2 sts=2 sw=2 et
augroup END

augroup js
  autocmd FileType javascript setlocal autoindent tw=79 ts=2 sts=2 sw=2 et
augroup END

augroup coffee
  autocmd FileType coffee setlocal autoindent tw=79 ts=4 sts=4 sw=4 et
augroup END

augroup ruby
  autocmd FileType ruby setlocal et ts=2 sw=2 sts=2 tw=79
  autocmd FileType eruby setlocal et ts=2 sw=2 sts=2 tw=79
  " Change identation keys.  The automatic indent when <Return> is used in any
  " place of the line is really crappy.
  autocmd FileType eruby setlocal indentkeys=o,O,<Return>,<>>,{,},0),0],o,O,!^F,=end,=else,=elsif,=rescue,=ensure,=when,=end,=else,=cat,=fina,=END,0\
augroup END

autocmd FileType yaml setlocal et ts=2 sw=2 sts=2 tw=79

augroup sgml
  " Treat Zope3's zcml files as xml, because actually they're it.
  autocmd BufNewFile,BufRead *.zcml set ft=xml

  autocmd BufNewFile,BufRead *.pt,*.cpt set ft=xml

  " Change identation keys.  The automatic indent when <Return> is used in any
  " place of the line is really crappy.
  autocmd FileType svg,xhtml,html,xml setlocal indentkeys=o,O,<>>,{,}
  autocmd FileType svg,xhtml,html,xml setlocal fo+=tl tw=79 ts=2 sw=2 sts=2 et
augroup END

augroup vim
  autocmd FileType vim setlocal tw=79 sw=4 ts=4 sts=4 et
augroup END

augroup clike
  autocmd FileType c,cpp,slang setlocal cindent
augroup END

augroup c
  autocmd FileType c setlocal fo+=ro
augroup END

augroup snippet
  autocmd FileType snippet setlocal noexpandtab sw=2 ts=2
augroup END


" General settings
" ================

" Session management
" ==================

" When quitting, save the session.
" autocmd! VimLeavePre * mksession!

" Load a session in the current directory.
map <F3> :so Session.vim<CR>

" Save the session and prompt for loading another.
nmap <F2> :wa<Bar>exe "mksession! " . v:this_session<CR>:so ~/vim-sessions/

" More
" ====

" Calculator using python
" -----------------------
if has('python3')
    command! -nargs=+ Calc :py3 print <args>
    py3 import math
elseif has('python')
    command! -nargs=+ Calc :py print <args>
    py import math
endif

" Syntastic configuration
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_auto_loc_list=1
let g:syntastic_enable_signs=1
let g:syntastic_python_checkers = ['flake8']

" Hilite trailing spaces as spelling errors
highlight link TrailingSpace SpellBad
autocmd Syntax * call matchadd('TrailingSpace', '\s\+$', 100)

" Hilite excess in long lines as spelling errors
function! s:MatchOverLength()
    let tw = &textwidth ? &textwidth : 80
    if &colorcolumn =~ "^+"
        " Sum &tw value with &cc value.
        let column = eval(tw.&colorcolumn)
    else
        if &colorcolumn != ''
            let column = &colorcolumn
        else
            let column = tw
        endif
    endif
    execute "match OverLength /.\\%>".column."v/"
endfunction
highlight link OverLength SpellBad
autocmd Syntax,WinEnter,WinLeave * call <sid>MatchOverLength()

let g:already_bored_with_overlength = 1

function! s:ToggleRelativeNumber()
    if &relativenumber
        set number
        autocmd! RelativeNumberAutoCommands
    else
        set relativenumber
        augroup RelativeNumberAutoCommands
            autocmd CursorMoved <buffer> call <sid>ToggleRelativeNumber()
        augroup END
    endif
endfunction

nmap <Leader>r :call <sid>ToggleRelativeNumber()<CR>


" Quickfixsigns: no icons.
let g:quickfixsigns_icons = {}


" CtrlP configuration
" -------------------

let g:ctrlp_open_new_file = 'r'
let g:ctrlp_default_input = 1
let g:ctrlp_user_command = "find -L %s -type f | egrep -v '\.(git|hg|svn|egg-info)/.*' | egrep -v '\.(pyc|pyo|swp)$'"
" let g:ctrlp_working_path_mode = 'rc'

if has('python3')
python3 << EOPython
import vim, sys
sys.path.append('/home/rcabralc/.vim/')
import ctrlp
EOPython
elseif has('python')
python << EOPython
import vim, sys
sys.path.append('/home/rcabralc/.vim/')
import ctrlp
EOPython
endif

let g:ctrlp_match_func = { 'match': 'FilterCtrlpList' }
