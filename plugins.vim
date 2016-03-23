if has('nvim')
    let vimdir = '~/.config/nvim/'
else
    let vimdir = '~/.vim/'
endif

let was_installed = 1

if !filereadable(expand(vimdir . "autoload/plug.vim"))
    call system('mkdir -p ' . vimdir . 'autoload')
    call system('curl -fLo ' . vimdir . 'autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
    execute 'source ' . vimdir . 'autoload/plug.vim'
    let was_installed = 0
endif

call plug#begin(vimdir . 'bundle')

" Filetypes/linters
Plug 'scrooloose/syntastic'
Plug 'sheerun/vim-polyglot'
Plug 'tpope/vim-git'
Plug 'dag/vim-fish'

" Colorschemes/themes
Plug 'morhetz/gruvbox'
Plug 'rcabralc/monokai.vim'
Plug '~/devel/vim/rcabralc-colorscheme.vim'
Plug '~/devel/vim/monokai-airline.vim/'
Plug '~/devel/vim/rcabralc-airline.vim/'

" Git
Plug 'tpope/vim-fugitive'

" EditorConfig
Plug 'editorconfig/editorconfig-vim'

" Better status/tab line
Plug 'itchyny/lightline.vim'

" Show lines changed
Plug 'airblade/vim-gitgutter'

" Toggle displaying indent steps
Plug 'nathanaelkane/vim-indent-guides'

" Comment in/out stuff easily
Plug 'tomtom/tcomment_vim'

" Edit things with sudo
Plug 'tpope/vim-eunuch'

" Easily change delimiters
Plug 'tpope/vim-surround'

" Keep layout when deleting/wiping buffers
Plug 'qpkorr/vim-bufkill'

" Nice start screen
Plug 'mhinz/vim-startify'

call plug#end()

if !was_installed
    PlugInstall
endif
