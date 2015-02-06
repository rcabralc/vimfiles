if !filereadable(expand("~/.vim/autoload/plug.vim"))
    !curl -fLo ~/.vim/autoload/plug.vim https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    source ~/.vim/autoload/plug.vim
endif

call plug#begin('~/.vim/bundle')

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
Plug '~/devel/vim/monokai.vim'
Plug '~/devel/vim/monokai-airline.vim/'

" Completion
Plug 'Shougo/neocomplete.vim'

call plug#end()

runtime! pluginconf.vim
