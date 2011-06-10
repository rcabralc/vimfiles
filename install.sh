#!/bin/sh
rm -rf bundle/
rm -rf vim-pathogen/

# Makes installation of plugins easier.
git clone http://github.com/tpope/vim-pathogen.git
mkdir bundle
cd bundle

# From now on all plugins are clonned into bundle/.

# Tim Pope stuff
git clone git://github.com/tpope/vim-abolish.git
git clone git://github.com/tpope/vim-fugitive.git
git clone git://github.com/tpope/vim-ragtag.git
git clone git://github.com/tpope/vim-rails.git
git clone git://github.com/tpope/vim-surround.git
git clone git://github.com/tpope/vim-endwise.git

# Nice ruby-debugger interface from inside Vim.
git clone git://github.com/astashov/vim-ruby-debugger.git

git clone git://github.com/mattn/zencoding-vim.git

# Syntax checking for python.
git clone git://github.com/kevinw/pyflakes-vim.git
# clone the PyFlakes fork.
rm -rf pyflakes-vim/ftplugin/python/pyflakes/
cd pyflakes-vim/ftplugin/python/
git clone git://github.com/kevinw/pyflakes.git
cd -

# Verifies syntax of files on save.
git clone git://github.com/scrooloose/syntastic.git

cd ../
