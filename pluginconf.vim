" Airline
" =======

if !exists('g:configured_airline')
    let g:airline_powerline_fonts = 0

    let g:airline_symbols = {}
    let g:airline_left_sep = ''
    let g:airline_left_alt_sep = '|'
    let g:airline_right_sep = ''
    let g:airline_right_alt_sep = '|'
    let g:airline_symbols.linenr = ''
    let g:airline_symbols.branch = ''
    let g:airline_symbols.paste = '∥'
    let g:airline_symbols.readonly = '⭤'
    let g:airline_symbols.whitespace = 'Ξ'

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

    let g:airline#extensions#tabline#enabled = 1
    let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
    let g:airline#extensions#tabline#left_sep = ''
    let g:airline#extensions#tabline#left_alt_sep = ''
    let g:airline#extensions#tabline#right_sep = ''
    let g:airline#extensions#tabline#right_alt_sep = ''

    let g:airline#extensions#whitespace#enabled = 1
    let g:airline#extensions#hunks#enabled = 1

    let g:airline_theme = 'monokai'

    let g:configured_airline = 1
end


" Fugitive
if exists('*fugitive#statusline')
    set statusline=%{fugitive#statusline()}%*%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
endif


" riv.vim
" =======

let g:riv_disable_folding = 1
let g:riv_highlight_code = 'lua,python,cpp,javascript,vim,sh,ruby'


" Colorscheme
" ===========

" if has('gui_running')
"   let g:indent_guides_auto_colors = 0
" endif
if !has('gui_running')
  let g:monokai_transparent_background = 1
endif

" Homebrewed fuzzy finder in Qt
" =============================
"
" Qt was choosen because:
"
"   1. I could do it from Python, and I feel confortable programming in this
"      language, which is a lot better than VimL.
"   2. I could use QtWebKit, and hence HTML, CSS and JavaScript to build the
"      UI, in which, again, I feel a lot more confortable than in VimL.
"   3. I like Qt, mainly because of KDE, and wanted to explore it.
"
" Despite the fact that it's done in Qt, it also works in console Vim.
"
" By now, launching a Qt process everytime a file or a buffer needs to be
" opened may be too slow when the memory is low, because Python will need to
" load lots of megabytes of modules/bindings/actual lib code from Qt, just to
" render a window, and the kernel will have to make room for that by swapping
" stuff out to the disk...  This is not optimal.  But this was the simplest
" (since my skills in VimL are far from good, and I don't like it) way to get
" it done.
"
" I see two possible solutions for this:
"
"   1. Use a daemon process (there's some outline in the Python module's doc
"      about this).  The daemon should be the heaviest part of this fuzzy
"      finder, so it'll load once and forever.  Further requests will only
"      bring it up, which can be a bit slow if the code got swapped to disk,
"      but still it's likely to be faster than the current implementation,
"      since it may happen that just some of its pages got swapped, while
"      others may be around in physical RAM.  Also, if many files are being
"      constantly opened through this fuzzy finder, the kernel is likely to
"      delay as much as possible the swapping of these pages.
"   2. Don't use Qt, just reimplement all of this functionality in a Vim split
"      window (just like CtrlP), but this requires some VimL skills.

" Find a file and pass it to cmd
function! FuzzyFileOpen(cmd)
    let dirname = resolve(expand('%:p:h'))
    let gittoplevel = system('cd ' . dirname . ' && git rev-parse --show-toplevel 2>/dev/null')
    let gittoplevel = substitute(gittoplevel, '\n$', '', '')

    if empty(gittoplevel)
        let initial = ''
        let toplevel = dirname
        let filescmd = 'cd ' .
                    \ shellescape(toplevel) .
                    \ ' && ag . -i --nocolor --nogroup --hidden '.
                    \ '--ignore .git '.
                    \ '--ignore .hg '.
                    \ '--ignore .DS_Store '.
                    \ '-g ""'
    else
        let toplevel = gittoplevel
        let gittoplevel = s:regexescape(gittoplevel)
        let initial = substitute(dirname, '^' . gittoplevel, '', '')
        let initial = substitute(initial, '^/', '', '')

        let filescmd = 'cd ' .
            \ shellescape(toplevel) .
            \ ' && git ls-files -co --exclude-standard | uniq'
    endif

    let menucmd = filescmd .
        \ ' | python -u ~/.vim/python/menu.py --limit 20 ' .
        \ '--completion-sep "/" ' .
        \ '--history-key ' . shellescape(toplevel)

    if !empty(initial)
        let menucmd = menucmd . " --input " . shellescape(initial) . '/'
    endif

    let menucmd = menucmd . " 2>/dev/null"
    let fname = Chomp(system(menucmd))

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  resolve(toplevel . '/' . fname)
endfunction
map <C-f> :call FuzzyFileOpen('e')<CR>

function! FuzzyBufferReOpen(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent ls
    redir END

    let menucmd = 'cat ' . tempfile .
        \ ' | grep "." ' .
        \ ' | sed "s/^.*\"\([^\"]*\)\".*\$/\\1/" ' .
        \ ' | python -u ~/.vim/python/menu.py --limit 100 2>/dev/null'

    let fname = Chomp(system(menucmd))

    call system('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction
map <C-b> :call FuzzyBufferReOpen('e')<CR>

" Strip the newline from the end of a string
function! Chomp(str)
    return substitute(a:str, '\n$', '', '')
endfunction

" Borrowed from somewhere in Internet, lost reference...
fu! s:regexescape(str)
  let str = a:str

  if exists('+ssl') && !&ssl
    let str = escape(str, '\')
  en

  for each in ['^', '$', '.']
    let str = escape(str, each)
  endfo

  return str
endfu


" Syntastic
" =========

if !exists('g:configured_syntastic') && exists('*SyntasticStatuslineFlag')
    set statusline+=%#warningmsg#
    set statusline+=%{SyntasticStatuslineFlag()}
    set statusline+=%*
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_enable_signs = 1
    let g:syntastic_python_checkers = ['flake8']
    let g:syntastic_ruby_checkers = ['rubocop']
    let g:syntastic_ruby_rubocop_args = '-D'

    let g:configured_syntastic = 1
end


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
