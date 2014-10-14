" Airline
" =======

" Use symbols in Airline (requires capable font, both in terminal and in GUI).
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

" Airline theme.
let g:airline_mode_map = {
    \ '__' : '-',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V',
    \ '' : 'V',
    \ 's'  : 'S',
    \ 'S'  : 'S',
    \ '' : 'S',
    \ }
let g:airline#extensions#hunks#enabled = 0
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_theme = 'monokai'


" Neocomplete
" ===========

let g:neocomplete#enable_at_startup = 1


" Colorscheme
" ===========

" if has('gui_running')
"   let g:indent_guides_auto_colors = 0
" endif
if !has('gui_running')
  let g:monokai_transparent_background = 1
endif

" CtrlP
" =====

let g:ctrlp_open_new_file = 'r'
let g:ctrlp_default_input = 1

let g:ctrlp_user_command = {
    \ 'types': {
        \ 1: ['.git', 'cd %s && git ls-files -co --exclude-standard | uniq'],
        \ 2: ['.hg', 'hg --cwd %s status -numac -I . $(hg root)'],
        \ },
    \ 'fallback': 'find %s -type f'
    \ }

if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor
    let g:ctrlp_user_command['fallback'] = 'ag %s -i --nocolor --nogroup --hidden '.
        \ '--ignore .git '.
        \ '--ignore .hg '.
        \ '--ignore .DS_Store '.
        \ '-g ""'
endif

let g:ctrlp_show_hidden = 1
let g:ctrlp_max_files = 0
let g:ctrlp_extensions = ['line']

if has('python3')
python3 <<PYTHON
import sys, os, vim
sys.path[0:0] = [os.path.join(os.path.expanduser('~'), '.vim', 'python')]
import ctrlp
PYTHON
elseif has('python')
python <<PYTHON
import sys, os, vim
sys.path[0:0] = [os.path.join(os.path.expanduser('~'), '.vim', 'python')]
import ctrlp
PYTHON
endif

let g:ctrlp_match_func = { 'match': 'CustomCtrlpMatch' }

fu! CustomCtrlpMatch(lines, input, limit, mmode, ispath, crfile, regexp)
    if a:ispath
        call filter(a:lines, 'v:val != a:crfile')
    endif

    let matchlist = FilterCtrlpList(a:lines, a:input, a:limit, a:mmode, a:regexp)

    call s:highlight(matchlist)

    return map(matchlist, 'v:val.original_value')
endfu

" call unite#custom#source('file,file/new,buffer,file_rec', 'matchers', 'matcher_fuzzy')
" nnoremap <C-p> :Unite -start-insert file_rec/async<CR>

" The function below as stolen from
" https://github.com/JazzCore/ctrlp-cmatcher/blob/master/autoload/matcher.vim
" Copyright 2010-2012 Wincent Colaiuta. All rights reserved.
fu! s:escapechars(chars)
  if exists('+ssl') && !&ssl
    cal map(a:chars, 'escape(v:val, ''\'')')
  en
  for each in ['^', '$', '.']
    cal map(a:chars, 'escape(v:val, each)')
  endfo

  return a:chars
endfu

fu! s:highlight(matchlist)
    call clearmatches()

    for i in range(len(a:matchlist))
        for j in range(len(a:matchlist[i]["spans"]))
            let highlight = a:matchlist[i]["spans"][j]

            let beginning = s:escapechars(highlight['beginning'])
            let middle = '\zs'.s:escapechars(highlight['middle']).'\ze'
            let ending = s:escapechars(highlight['ending'])

            call matchadd('CtrlPMatch', '\c'.beginning.middle.ending)
        endfor
    endfor
endf


" Syntastic
" =========

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_auto_loc_list=1
let g:syntastic_enable_signs=1
let g:syntastic_python_checkers = ['flake8']

" Filetypes
" =========

" Python highlighting options.
let python_highlight_all = 1
let python_slow_sync = 1

" Python filetype options.
let g:python_syntax_fold = 0
let g:python_fold_strings = 0
let g:python_auto_complete_modules = 0
let g:python_auto_complete_variables = 0

" Ruby highlighting options
let g:ruby_operators = 1
let g:ruby_space_errors = 1
let g:ruby_no_trail_space_error = 1 " As we already have support for this for all filetypes
let g:ruby_no_expensive = 1 " The colorscheme won't colorize `end' differently
let g:ruby_minlines = 200

" Ruby filetype options.
let g:ruby_indent_access_modifier_style = 'outdent'