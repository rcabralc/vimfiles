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
let g:fuzzy = {}

function! g:fuzzy.open(cmd, dirname, accept_input, info)
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
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'accept_input': a:accept_input,
        \ 'title': 'Select file from ' . info.toplevel
    \ })

    if empty(fname)
        return
    endif

    if fname == '..'
        return g:fuzzy.select_dir(a:cmd, s:getparent(info.toplevel), dirname, 1)
    endif

    if fname == '.'
        return g:fuzzy.select_dir(a:cmd, info.toplevel, info.toplevel, 1)
    endif

    execute a:cmd . " " .  g:utils.makepath(resolve(info.toplevel . '/' . fname))
endfunction

function! g:fuzzy.reopen(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent ls
    redir END

    let entriescmd = 'cat ' . tempfile .
        \ ' | grep "."' .
        \ ' | sed "s/^.*\"\([^\"]*\)\".*\$/\\1/"'

    let fname = s:spawn_menu(entriescmd, {
        \ 'limit': 100,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': 'Select buffer'
    \ })

    call g:utils.fish('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction

function! g:fuzzy.openold(cmd)
    let tempfile = tempname()

    execute "redir >" . tempfile
    silent oldfiles
    redir END

    let entriescmd = 'cat ' . tempfile .
        \ ' | grep "."' .
        \ ' | grep -v "term://"' .
        \ ' | grep -v ".git/"' .
        \ ' | grep -v "/tmp/nvim"' .
        \ ' | cut -d":" -f2- | sed "s/^\s\+//"'

    let fname = s:spawn_menu(entriescmd, {
        \ 'limit': 100,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': 'Select old file'
    \ })

    call g:utils.fish('rm ' . tempfile)

    if empty(fname)
        return
    endif

    execute a:cmd . " " .  fname
endfunction

function! g:fuzzy.select_dir(cmd, root, dirname, depth)
    let root = substitute(resolve(a:root), '/$', '', '')
    let entriescmd = s:gather_dirs(root, a:depth)

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
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': 'Select directory from ' . root,
        \ 'history_key': 'dir:' . root,
        \ 'input': initial
    \ })

    if empty(choice)
        return
    endif

    let choice = root . '/' . substitute(choice, '/$', '', '')

    return g:fuzzy.open(a:cmd, choice, 1, '')
endfunction

function! g:fuzzy.select_gem_dir(cmd, root)
    let root = s:rubygems_path(a:root)
    let entriescmd = s:gather_dirs(root, -1)

    let choice = s:spawn_menu(entriescmd, {
        \ 'limit': 20,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': 'Select gem from ' . root,
        \ 'history_key': 'gem:' . root
    \ })

    if empty(choice)
        return
    endif

    let choice = root . '/' . substitute(choice, '/$', '', '')

    return g:fuzzy.open(a:cmd, choice, 1, {
        \ 'initial': '',
        \ 'toplevel': choice,
        \ 'filescmd': g:utils.project_files_cmd(choice, {
            \ 'depth': -1
        \ })
    \ })
endfunction

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

    let entriescmd = 'cd ' . shellescape(root) . '; and find -L . '

    if a:maxdepth >= 0
        let entriescmd = entriescmd . '-maxdepth ' . a:maxdepth . ' '
    endif

    return entriescmd .
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
endfunction

function! s:rubygems_path(dirname)
    return g:utils.fish(
        \ 'rbenv exec gem environment | ' .
        \ 'grep -e "- INSTALLATION DIRECTORY" | cut -d : -f 2 | xargs', {
        \ 'cwd': a:dirname,
        \ 'chomp': 1
        \ }
    \)
endfunction

function! s:spawn_menu(entriescmd, params)
    if exists('g:python3_executable')
        let executable = g:python3_executable
    else
        let executable = 'python'
    endif

    let menucmd = executable . ' -u ' . g:vimdir . '/python/menu.py --daemonize'

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
