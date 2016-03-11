let g:polyglot_disabled = ['javascript']

" Colorscheme
" ===========

set background=dark
let g:indent_guides_auto_colors = 0
let g:rcabralc= { 'use_default_term_colors': 1 }
let g:monokai_colorscheme#use_default_term_colors = 1
colorscheme rcabralc


let g:lightline = { }
let g:lightline.colorscheme = 'rcabralc'
let g:lightline.active = {
    \ 'left': [ [ 'mode', 'paste' ],
    \           [ 'fugitive' ],
    \           [ 'syntastic' ],
    \           [ 'readonly', 'filename', 'modified' ] ],
    \ 'right': [ [ 'lineinfo' ],
    \            [ 'percent' ],
    \            [ 'filetype' ] ]
\ }
let g:lightline.inactive = {
    \ 'left': [ [ 'filename' ] ],
    \ 'right': [ [ 'lineinfo', 'percent' ] ]
\ }
let g:lightline.tabline = {
    \ 'left': [ [ 'tabs' ] ],
    \ 'right': [ [ 'close' ] ]
\ }
let g:lightline.component_function = {
    \ 'readonly': 'LightLineReadonly',
    \ 'fugitive': 'LightLineFugitive',
\ }
let g:lightline.component_expand = {
    \ 'syntastic': 'SyntasticStatuslineFlag',
\ }
let g:lightline.component_type = {
    \ 'syntastic': 'error',
\ }
let g:lightline.separator = { 'left': '⮀', 'right': '⮂' }
let g:lightline.subseparator = { 'left': '⮁', 'right': '⮃' }

function! LightLineReadonly()
    return &readonly ? '!' : ''
endfunction

function! LightLineFugitive()
    if !exists('*fugitive#head')
        return ''
    endif

    let _ = fugitive#head()
    return strlen(_) ? _ : ''
endfunction


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
function! FuzzyFileOpen(cmd, dirname, accept_input, info)
    let dirname = resolve(a:dirname)

    if empty(a:info)
        let info = s:project_root_info(dirname)
    else
        let info = a:info
    endif

    let fname = s:spawn_menu(info.filescmd, {
        \ 'limit': 20,
        \ 'input': info.initial,
        \ 'history_key': 'file:' . info.toplevel,
        \ 'word_delimiters': "/",
        \ 'accept_input': a:accept_input,
        \ 'title': 'Select file from ' . info.toplevel
    \ })

    if empty(fname)
        return
    endif

    if fname == '..'
        return FuzzyDirectorySelection(a:cmd, s:getparent(info.toplevel), dirname)
    endif

    if fname == '.'
        return FuzzyDirectorySelection(a:cmd, info.toplevel, info.toplevel)
    endif

    execute a:cmd . " " .  g:utils.makepath(resolve(info.toplevel . '/' . fname))
endfunction
map <C-f> :call FuzzyFileOpen('edit', expand('%:p:h'), 1, '')<CR>
map <C-p> :call FuzzyFileOpen('read', expand('%:p:h'), 0, '')<CR>

function! FuzzyBufferReOpen(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent ls
    redir END

    let entriescmd = 'cat ' . tempfile .
        \ ' | grep "."' .
        \ ' | sed "s/^.*\"\([^\"]*\)\".*\$/\\1/"'

    let fname = s:spawn_menu(entriescmd, {
        \ 'limit': 100,
        \ 'word_delimiters': "/",
        \ 'title': 'Select buffer'
    \ })

    call g:utils.fish('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction
map <Leader>b :call FuzzyBufferReOpen('e')<CR>

function! FuzzyOldFileReOpen(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent oldfiles
    redir END

    let entriescmd = 'cat ' . tempfile .
        \ ' | grep "."' .
        \ ' | grep -v ".git/"' .
        \ ' | grep -v "/tmp/nvim"' .
        \ ' | cut -d":" -f2- | sed "s/^\s\+//"'

    let fname = s:spawn_menu(entriescmd, {
        \ 'limit': 100,
        \ 'word_delimiters': "/",
        \ 'title': 'Select old file'
    \ })

    call g:utils.fish('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction
map <Leader>o :call FuzzyOldFileReOpen('e')<CR>

function! FuzzyDirectorySelection(cmd, root, dirname)
    let root = substitute(resolve(a:root), '/$', '', '')
    let entriescmd = s:gather_dirs(root, 5)

    if empty(a:dirname)
        let initial = ''
    else
        let initial = g:utils.relativepath(root, a:dirname)
    endif

    if !empty(initial)
        let initial = initial + '/'
    endif

    let choice = s:spawn_menu(entriescmd, {
        \ 'limit': 20,
        \ 'word_delimiters': "/",
        \ 'title': 'Select directory from ' . root,
        \ 'history_key': 'dir:' . root,
        \ 'input': initial
    \ })

    if empty(choice)
        return
    endif

    let choice = root . '/' . substitute(choice, '/$', '', '')

    return FuzzyFileOpen(a:cmd, choice, 1, '')
endfunction

function! FuzzyGemDirectorySelection(cmd, root)
    let root = s:rubygems_path(a:root)
    let entriescmd = s:gather_dirs(root, -1)

    let choice = s:spawn_menu(entriescmd, {
        \ 'limit': 20,
        \ 'word_delimiters': "/",
        \ 'title': 'Select gem from ' . root,
        \ 'history_key': 'gem:' . root
    \ })

    if empty(choice)
        return
    endif

    let choice = root . '/' . substitute(choice, '/$', '', '')

    return FuzzyFileOpen(a:cmd, choice, 1, {
        \ 'initial': '',
        \ 'toplevel': choice,
        \ 'filescmd': g:utils.project_files_cmd(choice)
    \ })
endfunction

map <Leader>g :call FuzzyGemDirectorySelection('e', expand('%:p:h'))<CR>

function! s:project_root_info(dirname)
    let toplevel = g:utils.project_root(a:dirname)
    let filescmd = g:utils.project_files_cmd(a:dirname)
    let initial = g:utils.relativepath(toplevel, a:dirname)

    if !empty(initial)
        let initial = initial . '/'
    endif

    return {
        \ 'initial': initial,
        \ 'toplevel': toplevel,
        \ 'filescmd': filescmd
    \ }
endfunction

function! s:gather_dirs(root, maxdepth)
    let root = substitute(resolve(a:root), '/$', '', '')

    if root == '/files/rcabralc'
        let root = $HOME
    end

    let entriescmd = 'cd ' . shellescape(root) . '; and find -L . '

    if a:maxdepth >= 0
        let entriescmd = entriescmd . '-maxdepth ' . a:maxdepth . ' '
    endif

    let entriescmd = entriescmd .
        \ '-type d \! -empty \( ' .
        \ '\( ' .
        \    '-path "./.wine" ' .
        \ '-o -path "./wine-diii" ' .
        \ '-o -path "./.cache" ' .
        \ '-o -path "./**/.git" ' .
        \ '-o -path "./**/.hg" ' .
        \ '-o -path "./**/__pycache__" ' .
        \ '-o -path "./**/*.egg-info" ' .
        \ '-o -path "./**/node_modules" ' .
        \ '-o -path "./**/bower_components" ' .
        \ '-o -path "./**/parts/omelette" ' .
        \ '\) ' .
        \ '-prune -o -print \) ' .
        \ '2>/dev/null | ' .
        \ 'sed "s/^\.\///" | sed "s/\$/\//"'

    if root == $HOME
        " For $HOME it'll be too much files to list, so avoid the selection of
        " its own.
        let entriescmd = entriescmd . ' | grep -v "^\./\$"'
    endif

    return entriescmd
endfunction

function! s:rubygems_path(dirname)
    return g:utils.fish(
        \ 'rbenv exec gem environment | ' .
        \ 'grep INSTALLATION | cut -d : -f 2 | xargs', {
        \ 'cwd': a:dirname,
        \ 'chomp': 1
        \ }
    \)
endfunction

function! s:spawn_menu(entriescmd, params)
    let menucmd = 'python -u ' . g:vimdir . '/python/menu.py --daemonize'

    if has_key(a:params, 'limit')
        let menucmd = menucmd . ' --limit ' . shellescape(a:params.limit)
    endif

    if has_key(a:params, 'completion_sep') && !empty(a:params.completion_sep)
        let menucmd = menucmd . ' --completion-sep ' . shellescape(a:params.completion_sep)
    endif

    if has_key(a:params, 'word_delimiters') && !empty(a:params.word_delimiters)
        let menucmd = menucmd . ' --word-delimiters ' . shellescape(a:params.word_delimiters)
    endif

    if has_key(a:params, 'history_key') && !empty(a:params.history_key)
        let menucmd = menucmd . ' --history-key ' . shellescape(a:params.history_key)
    endif

    if has_key(a:params, 'accept_input') && a:params.accept_input
        let menucmd = menucmd . ' --accept-input'
    endif

    if has_key(a:params, 'title') && !empty(a:params.title)
        let menucmd = menucmd . ' --title ' . shellescape(a:params.title)
    endif

    if has_key(a:params, 'input') && !empty(a:params.input)
        let menucmd = menucmd . ' --input ' . shellescape(a:params.input)
    endif

    let cmd = a:entriescmd . ' | ' . menucmd
    return g:utils.fish(cmd . ' 2>/tmp/debug.log', { 'chomp': 1 })
endfunction

function! s:getparent(dirname)
    py import os.path, vim
    return '/' . pyeval("os.path.join(*vim.eval('a:dirname').split(os.path.sep)[:-1])")
endfunction


" Syntastic
" =========

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1

let g:syntastic_javascript_checkers = ['jshint', 'jscs']
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_ruby_rubocop_args = '-D'


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
