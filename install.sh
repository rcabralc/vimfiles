#!/bin/sh
mkdir bundle
git clone http://github.com/tpope/vim-pathogen.git/
cd bundle
git clone http://github.com/tpope/vim-abolish.git/
git clone http://github.com/tpope/vim-fugitive.git/
git clone http://github.com/tpope/vim-ragtag.git/
git clone http://github.com/tpope/vim-rails.git/
git clone http://github.com/astashov/vim-ruby-debugger.git/
git clone http://github.com/tpope/vim-surround.git/
git clone http://github.com/mattn/zencoding-vim.git/
cd ../
