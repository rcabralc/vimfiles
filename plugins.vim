if has('vim_starting')
    set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Activate NeoBundle
call neobundle#begin(expand('~/.vim/bundle/'))

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

call neobundle#end()

filetype plugin indent on

NeoBundleCheck
