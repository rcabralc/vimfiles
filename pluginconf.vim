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
" A fuzzy finder that runs outside the Vim process, thus not succeptible to
" slow syntax highlighting.  This could be a curses-based application, or a
" graphical one (in GTK or Qt or something else).  A graphical application
" suits better for use with GVim.  Qt was choosen because:
"
"   1. I could do it from Python, and I feel confortable programming in this
"      language, which is a lot better than VimL.
"   2. I could use QtWebKit, and hence HTML, CSS and JavaScript to build the
"      UI, in which, again, I feel a lot more confortable than in VimL.
"   3. I like Qt, mainly because of KDE, and wanted to explore it.
"
" Despite the fact that it's done in Qt, it also works in console Vim, provided
" it runs inside an emulated terminal (a graphical server is needed).
"
" Additionally, to avoid re-importing Qt modules everytime a file or a buffer
" needs to be opened, a simple process is used, which only sends to the
" daemonized process which has the Qt stuff the data it needs (the list of
" files/buffers to select from, and some options).  This is specially useful in
" low memory condition, when the kernel otherwise would have to make room in
" RAM for lots of python bindings by swapping stuff to disk everytime the menu
" were launched.  A daemon constantly used (the portion which has the heavy Qt
" stuff) may take advantage of kernel heuristics and be kept in memory most of
" the time, avoiding hitting disk/swap to present the menu.  The process which
" communicates with the daemon is lighter (it just does UNIX socket stuff), and
" should not cause anoying delays when launched.
function! FuzzyFileOpen(cmd, dirname)
    let info = s:project_root_info(a:dirname)
    let fname = s:spawn_menu(info.filescmd, {
        \ 'limit': 20,
        \ 'completion_sep': '/',
        \ 'input': info.initial,
        \ 'history_key': info.toplevel
    \ })

    if empty(fname)
        return
    endif

    if fname == '..'
        return FuzzyFileOpen(a:cmd, s:getparent(a:dirname))
    endif

    execute a:cmd . " " .  s:makepath(resolve(info.toplevel . '/' . fname))
endfunction
map <C-f> :call FuzzyFileOpen('edit', resolve(expand('%:p:h')))<CR>
map <C-p> :call FuzzyFileOpen('read', resolve(expand('%:p:h')))<CR>

function! FuzzyBufferReOpen(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent ls
    redir END

    let entriescmd = 'cat ' . tempfile .
        \ ' | grep "."' .
        \ ' | sed "s/^.*\"\([^\"]*\)\".*\$/\\1/"'

    let fname = s:spawn_menu(entriescmd, { 'limit': 100, 'completion_sep': '/' })

    call system('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction
map <C-b> :call FuzzyBufferReOpen('e')<CR>

function! s:project_root_info(dirname)
    let gittoplevel = s:chomp(system('cd ' . a:dirname . ' && git rev-parse --show-toplevel 2>/dev/null'))

    if empty(gittoplevel)
        let initial = ''
        let toplevel = a:dirname
        let filescmd = 'cd ' .
                    \ shellescape(toplevel) .
                    \ ' && ag . -i --nocolor --nogroup --hidden '.
                    \ '--ignore .git '.
                    \ '--ignore .hg '.
                    \ '--ignore .DS_Store '.
                    \ '--ignore *.swp '.
                    \ '-g ""'
    else
        let initial = s:relativepath(gittoplevel, a:dirname)
        let toplevel = gittoplevel
        let filescmd = 'cd ' .
                    \ shellescape(toplevel) .
                    \ ' && git ls-files -co --exclude-standard | uniq'
    endif

    if !empty(initial)
        let initial = initial . '/'
    endif

    return {
        \ 'initial': initial,
        \ 'toplevel': toplevel,
        \ 'filescmd': filescmd
    \ }
endfunction

function! s:spawn_menu(entriescmd, params)
    let menucmd = 'python -u ~/.vim/python/menu.py --daemonize'

    if has_key(a:params, 'limit')
        let menucmd = menucmd . ' --limit ' . shellescape(a:params.limit)
    endif

    if has_key(a:params, 'completion_sep') && !empty(a:params.completion_sep)
        let menucmd = menucmd . ' --completion-sep ' . shellescape(a:params.completion_sep)
    endif

    if has_key(a:params, 'history_key') && !empty(a:params.history_key)
        let menucmd = menucmd . ' --history-key ' . shellescape(a:params.history_key)
    endif

    if has_key(a:params, 'input') && !empty(a:params.input)
        let menucmd = menucmd . ' --input ' . shellescape(a:params.input)
    endif

    return s:chomp(system(a:entriescmd . ' | ' . menucmd . ' 2>/dev/null'))
endfunction

" Strip the newline from the end of a string
function! s:chomp(str)
    return substitute(a:str, '\n$', '', '')
endfunction

function! s:relativepath(basepath, path)
    let rel = substitute(a:path, '^' . s:regexescape(a:basepath), '', '')
    return substitute(rel, '^/', '', '')
endfunction

function! s:makepath(file)
    let basedir = []
python <<EOP
import os.path, vim
vim.bindeval('basedir').extend([os.path.dirname(vim.eval('a:file'))])
EOP
    call system('mkdir -p ' . shellescape(basedir[0]))
    return a:file
endfunction

function! s:getparent(dirname)
    let result = []
python <<EOP
import os.path as p, vim
vim.bindeval('result').extend([
    '/' + p.join(*vim.eval('a:dirname').split(p.sep)[:-1])
])
EOP
    return result[0]
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
