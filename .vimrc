" ===================
" Configuração padrão
" ===================

" Interface
" =========

" Nocompatible mode
set nocompatible

" limpe qualquer autocommand existente
autocmd!

" permita que arquivos definam configuração
set modeline

" destaque linha e coluna do cursor
set cursorline cursorcolumn

" permita uso do mouse em todos os modos
" set mouse=a

" exiba os números de linha
" set number

" tenha cinquenta linhas de histórico
set history=50

" always show the status line
set laststatus=2

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
set bg=dark

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
let transparent_background=1
colorscheme rcabralc

" Movimentação/navegação
" ======================

" Navigate between buffers (only normal mode)
nnoremap <C-N> :bn!<CR>
nnoremap <C-P> :bp!<CR>

" B prompts for opening a buffer
nnoremap B :buffer<Space>

" E prompts for a new file (in a new buffer)
nnoremap E :edit<Space>

" <Leader>D kills a buffer and close the window, <Leader>d kills a buffer but
" preserve the window.
map <Leader>d :call KillBuffer()<CR>
function! KillBuffer()
  let num = bufnr('%')
  bn
  execute "bw " . num
endfunction
map <Leader>D :bw<CR>

" <F3> opens/closes the NERDTree window
nmap <F3> :NERDTreeToggle<CR><C-W>=

" <C-F> finds the current buffer in the tree.
nmap <C-F> :call FindInNERDTree()<CR>

" Window
" ------

" navigate between windows without pressing C-W
nnoremap <C-h> <C-W><C-h>
nnoremap <C-j> <C-W><C-j>
nnoremap <C-k> <C-W><C-k>
nnoremap <C-l> <C-W><C-l>

" Mappings for breaking lines on every white space
nnoremap <Leader>b f<Space>xi<CR><ESC>_
nnoremap <Leader>B F<Space>xi<CR><ESC>_

" Mappings for breaking lines at 72 chars
nmap <Leader>w 073l\B

" For Emacs-style editing on the command-line:
" start of line
cnoremap <C-A>		<Home>
" back one character
cnoremap <C-B>		<Left>
" delete character under cursor
cnoremap <C-D>		<Del>
" end of line
cnoremap <C-E>		<End>
" forward one character
cnoremap <C-F>		<Right>
" recall newer command-line
cnoremap <C-N>		<Down>
" recall previous (older) command-line
cnoremap <C-P>		<Up>
" back one word
cnoremap <Esc><C-B>	<S-Left>
" forward one word
cnoremap <Esc><C-F>	<S-Right>

" Formatação de texto
" ===================

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

" get rid of the default style of C comments, and define a style with two stars
" at the start of `middle' rows which (looks nicer and) avoids asterisks used
" for bullet lists being treated like C comments; then define a bullet list
" style for single stars (like already is for hyphens):
set comments-=s1:/*,mb:*,ex:*/
set comments+=s:/*,mb:**,ex:*/
set comments+=fb:*

" treat lines starting with a quote mark as comments (for `Vim' files, such as
" this very one!), and colons as well so that reformatting usenet messages from
" `Tin' users works OK:
set comments+=b:\"
set comments+=n::


" Tipos de arquivos específicos
" =============================

" detecte os tipos de arquivo
filetype plugin indent on

" geral
augroup general
  autocmd BufNewFile,BufRead *.txt set filetype=human

  " Treat Zope3's zcml files as xml, because actually they're it.
  autocmd BufNewFile,BufRead *.zcml set ft=xml

  " Treat Zope's template files as xhtml, because the TAL implementation is
  " compatible with this.
  autocmd BufNewFile,BufRead *.pt,*.cpt set filetype=xhtml

  " Treat Plone's CSS files (actually DTML methods) as CSS files, as well KSS
  " files.
  autocmd BufNewFile,BufRead *.css.dtml,*.kss set filetype=css
augroup END

augroup python
  " This is for the tComment plugin.  Strangely, it doesn't define a python
  " comment string.  This worked until I recently work on a kubuntu 9.04 box...
  " autocmd FileType python call TCommentDefineType('python', '# %s')

  " Recognize Zope's controller python scripts and validators as python.
  autocmd BufNewFile,BufRead *.cpy,*.vpy set filetype=python

  " Default python identation, as recommended by PEP8.
  autocmd FileType python set et ts=4 sw=4 sts=4

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

  " Syntax highlightning for doctest
  autocmd FileType rst set syntax=doctest
augroup END

augroup css
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
augroup END

augroup xmllike
  autocmd FileType xhtml,html,xml set nosmartindent
  " Change identation keys.  The automatic indent when <Return> is used in any
  " place of the line is really crappy.
  autocmd FileType xhtml,html,xml setlocal indentkeys=o,O,<>>,{,}
  autocmd FileType xhtml,html,xml set fo+=tl tw=79 ts=2 sw=2 sts=2 et
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


" Procura e substituição
" ======================

" case-insensitive, a menos que haja maiúsculas
set ignorecase
set smartcase

" incremental
set incsearch


" General settings
" ================

" Settings for the selectbuf plugin
" ---------------------------------

let g:selBufAlwaysShowDetails=1
let g:selBufAlwaysShowHidden=1
let g:selBufAlwaysShowPaths=2
