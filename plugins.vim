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
Plug 'w0rp/ale'
Plug 'sheerun/vim-polyglot'
Plug 'vim-ruby/vim-ruby'

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

" Display indent steps
Plug 'Yggdroot/indentLine'

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

" Highlight all matches when incsearching
Plug 'haya14busa/incsearch.vim'
Plug 'haya14busa/incsearch-fuzzy.vim'
Plug 'haya14busa/vim-asterisk'

" Table mode
Plug 'dhruvasagar/vim-table-mode'

" SQL from within VIM
Plug 'vim-scripts/dbext.vim'

" Autocompletion
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" Text object for function arguments
Plug 'b4winckler/vim-angry'

" Many handy text objects
Plug 'wellle/targets.vim'

" Easy swap of text objects
Plug 'tommcdo/vim-exchange'

" Easy selection expansing/contraction
Plug 'terryma/vim-expand-region'

" Make . work with surround (and other plugins)
Plug 'tpope/vim-repeat'

call plug#end()

if !was_installed
    PlugInstall
endif
