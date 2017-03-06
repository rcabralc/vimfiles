set number
set mouse=
set autoindent
set noshowmode

" Assume a capable terminal.
if has('nvim')
    set termguicolors
    let $NVIM_TUI_ENABLE_CURSOR_SHAPE = '1'
endif

" Smart indent is crap.
set nosmartindent

" The world is not prepared for deviations
set shell=/bin/bash

" Ensure backspace behavior is not alien.
set backspace=indent,eol,start

" Allow modelines.
set modeline

" Turn on command line completion wild style.
set wildmenu

" have command-line completion <Tab> (for filenames, help topics, option names)
" first complete to longest common string, then list the available options and
" complete the first optiont, then have further <Tab>s cycle through the
" possibilities:
set wildmode=longest,list:longest,list:full

" Leave the cursor where it was.
set nostartofline

" Keep some lines around for scope.
set scrolloff=10

set history=50

" always show the status line.
set laststatus=2

" Lazy redraw.
set lazyredraw

" display the current mode and partially-typed commands in the status line:
set showmode
set showcmd

set nowrap

" Allow buffer swapps without having to write them to disk.
set hidden

" Wrap search around the end of the file
set wrapscan

" Mostly troublesome.
set nrformats-=octal

set shiftround

" The colorscheme is not too invasive, so highlight searched terms.
set hlsearch

set ignorecase
set smartcase
set incsearch

set fillchars=vert:│,fold:-

" Mark text width column.
set colorcolumn=+1

" Use indents of 2 spaces, and have them copied down lines.
set shiftwidth=2
set shiftround
set expandtab
set smarttab

" Text width at 79 chars allows me to easily split windows vertically.
set textwidth=79

" Reduce the maximum column in which syntax is applied.  Following lines may
" have syntax highlighting compromised.  (defaults to 3000)
set synmaxcol=200

set cursorline
set nofoldenable
