if has('nvim')
    let vimdir = '~/.config/nvim/'
else
    let vimdir = '~/.vim/'
endif

let was_installed = 1

if !filereadable(expand(vimdir . "autoload/plug.vim"))
    call system('curl -fLo ' . vimdir . 'autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
    execute 'source ' . vimdir . 'autoload/plug.vim'
    let was_installed = 0
endif

call plug#begin(vimdir . 'bundle')

" Filetypes/linters
Plug 'scrooloose/syntastic'
Plug 'sheerun/vim-polyglot'

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

" Unix stuff, including editing things with sudo
Plug 'tpope/vim-eunuch'

" Add end to ruby blocks automatically
Plug 'tpope/vim-endwise'

" Easily change delimiters
Plug 'tpope/vim-surround'

" Keep layout when deleting/wiping buffers
Plug 'qpkorr/vim-bufkill'

" Highlight colors
Plug 'ap/vim-css-color'

" Automatically change dir when opening files
Plug 'airblade/vim-rooter'

" HTTP client
Plug 'diepm/vim-rest-console'

" SQL from within VIM
Plug 'vim-scripts/dbext.vim'

" Autocompletion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

call plug#end()

if !was_installed
    PlugInstall
endif
