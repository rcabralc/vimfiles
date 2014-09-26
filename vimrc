" vim et sw=4
" ===================
" Configuração padrão
" ===================

set nocompatible " Be iMproved

set shell=/bin/sh " Avoid problems with fish shell

" Plugins
" =======

if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Activate NeoBundle
call neobundle#rc(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'cygwin' : 'make -f make_cygwin.mak',
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }

NeoBundle 'rcabralc/monokai.vim'
NeoBundle 'vim-scripts/VST'
NeoBundle 'editorconfig/editorconfig-vim'
NeoBundle 'othree/html5.vim'
NeoBundle 'bling/vim-airline'
NeoBundle 'airblade/vim-gitgutter'
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
NeoBundle 'osyo-manga/vim-over'
NeoBundle 'edsono/vim-matchit'
NeoBundle 'nvie/vim-rst-tables'
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'vim-scripts/bufkill.vim'
NeoBundle 'dag/vim-fish'
NeoBundle '/home/rcabralc/devel/vim/monokai-airline.vim/', { 'type': 'nosync' }

" Fuzzy file finder
NeoBundle 'kien/ctrlp.vim'

" Completion
NeoBundle 'Shougo/neocomplete.vim'

filetype plugin indent on
syntax enable

NeoBundleCheck

augroup Misc
    autocmd!
augroup END


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

" Highlight cursor line and column
set cursorline cursorcolumn
augroup Misc
    autocmd WinLeave * set nocursorline nocursorcolumn
    autocmd WinEnter * set cursorline cursorcolumn
augroup END

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
" first complete to longest common string, then list the available options and
" complete the first optiont, then have further <Tab>s cycle through the
" possibilities:
set wildmode=list:longest,list:full

" display the current mode and partially-typed commands in the status line:
set showmode
set showcmd

set nowrap

" permita que buffers sejam trocados sem perder as alterações
set hidden

" Wrap search around the end of the file
set wrapscan

" Mostly troublesome.
set nrformats-=octal

set shiftround

" Don't wait forever on key codes.
set ttimeout
set ttimeoutlen=100
set noesckeys

" The colorscheme is not too invasive, so highlight searched terms.
set hlsearch

set smartcase
set incsearch

set fillchars=vert:│,fold:-

" Briefly jump to matching paren or bracket.  This is not milliseconds, but the
" docs don't say what it is.
" set showmatch
" set matchtime=3

" Use symbols in Airline (requires capable font, both in terminal and in GUI).
let g:airline_powerline_fonts = 1


" Colors
" ======

syntax on

" configuração de cores para fundo escuro
" set bg=dark

" Set the number of colors to 256.  This requires a capable terminal.
set t_Co=256

" if has('gui_running')
"   let g:indent_guides_auto_colors = 0
"   colorscheme rcabralc
" endif
if !has('gui_running')
  let g:monokai_transparent_background = 1
endif
colorscheme monokai

" Mark text width column.
set colorcolumn=+1


" Mappings
" ========

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

nmap <Leader>r :%s///gc

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

" Neocomplete
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>NeocompleteCR()<CR>
function! s:NeocompleteCR()
    return neocomplete#close_popup() . "\<CR>"
    " For no inserting <CR> key.
    "return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction


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

" Ruby filetype options.
let g:ruby_indent_access_modifier_style = 'outdent'


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
  autocmd FileType markdown,rst,human,mail,gitcommit setlocal ai fo=tcroqn tw=78 et sw=2 ts=2 sts=2
  autocmd FileType mail,human,gitcommit setlocal tw=72
  " " Git commits wrapped in 72 columns, so we can have four columns at left for
  " " indentation (as git log does) and four columns at right (for symmetry) and
  " " still have all the message fit in a 80-columns terminal.

  " Syntax highlighting for doctest
  autocmd FileType rst setlocal syntax=doctest

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

  autocmd FileType svg,xhtml,html,xml imap <buffer> <Leader>xc </<c-x><c-o><esc>a
  autocmd FileType svg,xhtml,html,xml imap <buffer> <Leader>Xc </<c-x><c-o><esc>F<i
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

augroup fish
  autocmd FileType fish compiler fish
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

highlight! TrailingSpace ctermbg=red guibg=red
match TrailingSpace /\s\+$/

augroup Misc
    autocmd BufWinEnter * if &modifiable && &ft!='unite' | match TrailingSpace /\s\+$/ | endif
    autocmd InsertEnter * if &modifiable && &ft!='unite' | match TrailingSpace /\s\+\%#\@<!$/ | endif
    autocmd InsertLeave * if &modifiable && &ft!='unite' | match TrailingSpace /\s\+$/ | endif
    autocmd BufWinLeave * if &modifiable && &ft!='unite' | call clearmatches() | endif
augroup END

function! s:ToggleRelativeNumber()
    if &relativenumber
        set norelativenumber
    else
        set relativenumber
    endif
endfunction

nmap <Leader>n :call <sid>ToggleRelativeNumber()<CR>


" CtrlP configuration
" -------------------

let g:ctrlp_open_new_file = 'r'
let g:ctrlp_default_input = 1

let g:ctrlp_user_command = {
    \ 'types': {
        \ 1: ['.git', 'cd %s && git ls-files -co --exclude-standard | uniq'],
        \ 2: ['.hg', 'hg --cwd %s status -numac -I . $(hg root)'],
        \ },
    \ 'fallback': 'find %s -type f'
    \ }

if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor
    let g:ctrlp_user_command['fallback'] = 'ag %s -i --nocolor --nogroup --hidden '.
        \ '--ignore .git '.
        \ '--ignore .hg '.
        \ '--ignore .DS_Store '.
        \ '-g ""'
endif

let g:ctrlp_show_hidden = 1
let g:ctrlp_max_files = 0
let g:ctrlp_extensions = ['line']

if has('python3')
python3 <<PYTHON
import sys, os, vim
sys.path[0:0] = [os.path.join(os.path.expanduser('~'), '.vim', 'python')]
import ctrlp
PYTHON
elseif has('python')
python <<PYTHON
import sys, os, vim
sys.path[0:0] = [os.path.join(os.path.expanduser('~'), '.vim', 'python')]
import ctrlp
PYTHON
endif

let g:ctrlp_match_func = { 'match': 'CustomCtrlpMatch' }

fu! CustomCtrlpMatch(lines, input, limit, mmode, ispath, crfile, regexp)
    if a:ispath
        call filter(a:lines, 'v:val != a:crfile')
    endif

    let matchlist = FilterCtrlpList(a:lines, a:input, a:limit, a:mmode, a:regexp)

    call s:highlight(matchlist)

    return map(matchlist, 'v:val.original_value')
endfu

" call unite#custom#source('file,file/new,buffer,file_rec', 'matchers', 'matcher_fuzzy')
" nnoremap <C-p> :Unite -start-insert file_rec/async<CR>

" The function below as stolen from
" https://github.com/JazzCore/ctrlp-cmatcher/blob/master/autoload/matcher.vim
" Copyright 2010-2012 Wincent Colaiuta. All rights reserved.
fu! s:escapechars(chars)
  if exists('+ssl') && !&ssl
    cal map(a:chars, 'escape(v:val, ''\'')')
  en
  for each in ['^', '$', '.']
    cal map(a:chars, 'escape(v:val, each)')
  endfo

  return a:chars
endfu

fu! s:highlight(matchlist)
    call clearmatches()

    for i in range(len(a:matchlist))
        for j in range(len(a:matchlist[i]["spans"]))
            let highlight = a:matchlist[i]["spans"][j]

            let beginning = s:escapechars(highlight['beginning'])
            let middle = '\zs'.s:escapechars(highlight['middle']).'\ze'
            let ending = s:escapechars(highlight['ending'])

            call matchadd('CtrlPMatch', '\c'.beginning.middle.ending)
        endfor
    endfor
endf


" Airline
" =======

let g:airline#extensions#tabline#enabled = 1


" Neocomplete
" ===========

let g:neocomplete#enable_at_startup = 1


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

    " <C-k> interferes with the mapping to switch to the window above.
    " autocmd FileType vimshell nunmap <buffer> <C-k>

    " Make text wrap.
    autocmd FileType qf setlocal wrap
augroup END


" Airline theme.
let g:airline_mode_map = {
    \ '__' : '-',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V',
    \ '' : 'V',
    \ 's'  : 'S',
    \ 'S'  : 'S',
    \ '' : 'S',
    \ }
let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_theme = 'monokai'

" Soft motions
" ------------
runtime! softmotions.vim


" Highlighting optimizations
" --------------------------
hi! link rubyBlockParameter Special

hi! link javaScriptFuncExp Normal
hi! link javaScriptGlobal Normal
" Strangely enough, these JS identifiers are actually keywords.
hi! link javaScriptIdentifier Keyword
" I don't care that these be not highlighted in a special way.
hi! link javaScriptHtmlElemProperties Normal
