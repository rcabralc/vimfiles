#!/bin/sh
rm -rf bundle/
rm -rf vim-pathogen/
git clone http://github.com/tpope/vim-pathogen.git/
mkdir bundle
cd bundle
git clone http://github.com/tpope/vim-abolish.git/
git clone http://github.com/tpope/vim-fugitive.git/
git clone http://github.com/tpope/vim-ragtag.git/
git clone http://github.com/tpope/vim-rails.git/
git clone http://github.com/astashov/vim-ruby-debugger.git/
git clone http://github.com/tpope/vim-surround.git/
git clone http://github.com/mattn/zencoding-vim.git/
git clone http://github.com/kevinw/pyflakes-vim.git
# clone the PyFlakes fork.
rm -rf pyflakes-vim/ftplugin/python/pyflakes/
cd pyflakes-vim/ftplugin/python/
git clone http://github.com/kevinw/pyflakes.git
cd -
cd ../
