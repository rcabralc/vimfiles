let python_highlight_all = 1
let python_slow_sync = 1

" The syntax file called here is the python.vim from vim.org.  This file
" actually is a customization layer over the default from vim.org.
set syntax=python_

" Hilite trailing spaces as errors.
syntax match pythonError "\s\+$"
