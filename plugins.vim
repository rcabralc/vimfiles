if match($VIM, 'nvim') == -1
    let vimdir = '~/.vim/'
else
    let vimdir = '~/.nvim/'
endif

let was_installed = 1

if !filereadable(expand(vimdir . "autoload/plug.vim"))
    call system('mkdir -p ' . vimdir . 'autoload')
    call system('curl -fLo ' . vimdir . 'autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim')
    execute 'source ' . vimdir . 'autoload/plug.vim'
    let was_installed = 0
endif

call plug#begin(vimdir . 'bundle')

Plug 'Rykka/riv.vim'
"Plug 'vim-scripts/VST'
Plug 'editorconfig/editorconfig-vim'
Plug 'othree/html5.vim'
Plug 'bling/vim-airline'
Plug 'airblade/vim-gitgutter'
Plug 'cakebaker/scss-syntax.vim'
Plug 'msanders/snipmate.vim'
Plug 'scrooloose/syntastic'
Plug 'tomtom/tcomment_vim'
Plug 'kchmck/vim-coffee-script'
Plug 'hail2u/vim-css3-syntax'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-git'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'jelera/vim-javascript-syntax'
Plug 'osyo-manga/vim-over'
Plug 'edsono/vim-matchit'
Plug 'nvie/vim-rst-tables'
Plug 'vim-ruby/vim-ruby'
Plug 'vim-scripts/bufkill.vim'
Plug 'dag/vim-fish'
Plug 'christoomey/vim-tmux-navigator'
Plug 'tmux-plugins/vim-tmux'
Plug '~/devel/vim/monokai.vim'
Plug '~/devel/vim/monokai-airline.vim/'

call plug#end()

if !was_installed
    execute "PlugInstall"
endif

runtime! pluginconf.vim
