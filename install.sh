#!/bin/sh

# Update submodules
git submodule update --init

# Syntax checking for python.
# Clone the PyFlakes fork.  We can't do this using the submodule because its
# url requires authentication.
rm -rf bundle/pyflakes-vim/ftplugin/python/pyflakes/
cd bundle/pyflakes-vim/ftplugin/python/
git clone git://github.com/kevinw/pyflakes.git
cd -
