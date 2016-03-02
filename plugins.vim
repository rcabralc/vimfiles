if has('nvim')
    let vimdir = '~/.vim/'
else
    let vimdir = '~/.config/nvim/'
endif

let was_installed = 1

if !filereadable(expand(vimdir . "autoload/plug.vim"))
    call system('mkdir -p ' . vimdir . 'autoload')
    call system('curl -fLo ' . vimdir . 'autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
    execute 'source ' . vimdir . 'autoload/plug.vim'
    let was_installed = 0
endif

call plug#begin(vimdir . 'bundle')

Plug 'mhinz/vim-startify'
Plug 'editorconfig/editorconfig-vim'
Plug 'sheerun/vim-polyglot'
Plug 'itchyny/lightline.vim'
Plug 'airblade/vim-gitgutter'
Plug 'scrooloose/syntastic'
Plug 'tomtom/tcomment_vim'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-surround'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'edsono/vim-matchit'
Plug 'vim-scripts/bufkill.vim'
Plug 'dag/vim-fish'
Plug 'morhetz/gruvbox'
Plug 'rcabralc/monokai.vim'
Plug '~/devel/vim/rcabralc-colorscheme.vim'
Plug '~/devel/vim/monokai-airline.vim/'
Plug '~/devel/vim/rcabralc-airline.vim/'

call plug#end()

if !was_installed
    PlugInstall
endif
