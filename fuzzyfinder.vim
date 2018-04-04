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

function! s:select(dirname, cmd, accept_input, info)
    " resolve() mangles fugitive:// paths.
    if match(a:dirname, '^fugitive:\/\/') == 0
        let dirname = a:dirname
    else
        let dirname = resolve(a:dirname)
    endif

    if empty(a:info)
        let info = s:project_root_info(dirname)
    else
        let info = a:info
    endif

    if g:utils.looks_like_gitroot(info.toplevel)
        let title = ':'.a:cmd.' file from Git repo at ' . info.toplevel
    else
        let title = ':'.a:cmd.' from ' . info.toplevel
    endif

    let choice = g:utils.menucmd({
        \ 'limit': 20,
        \ 'input': info.initial,
        \ 'history_key': 'file:' . info.toplevel,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'accept_input': a:accept_input,
        \ 'title': title
    \ }).pipe_from(info.filescmd).output()

    if empty(choice)
        return
    endif

    let resolved = resolve(info.toplevel . '/' . choice)

    if isdirectory(resolved)
        return s:select(resolved, a:cmd, a:accept_input, a:info)
    endif

    return resolved
endfunction

function! g:fuzzy.open(command, dirname, ...)
    let info = a:0 ? a:1 : ''
    let choice = s:select(a:dirname, a:command, 1, info)
    if empty(choice)
        return
    endif
    execute a:command . ' ' . g:utils.makepath(choice)
endfunction

function! g:fuzzy.read(dirname, ...)
    let info = a:0 ? a:1 : ''
    let choice = s:select(a:dirname, 'read', 0, info)
    if empty(choice)
        return
    endif
    execute 'read ' . choice
endfunction

function! g:fuzzy.open_from_branch()
    let filename = expand('%:p')
    let root = g:utils.gitroot(filename)
    if empty(root)
        return
    endif

    let branch = g:gitcommand.select_branch(root)

    if empty(branch)
        return
    endif

    let entriescmd = g:utils.fish('git ls-tree -r --name-only ' . branch, {
        \ 'cwd': root,
        \ 'cmd': 1
    \ })
    let fname = g:utils.menucmd({
        \ 'limit': 20,
        \ 'input': g:utils.relativepath(root, filename),
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': 'Select file from Git branch ' . branch
    \ }).pipe_from(entriescmd).output()

    if empty(fname)
        return
    endif

    execute 'Gedit ' . branch . ':' . fname
endfunction

function! g:fuzzy.reopen(cmd)
    let entriescmd = 'grep -v " a- " ' .
        \ ' | grep "."' .
        \ ' | sed "s/^.*\"\([^\"]*\)\".*\$/\\1/"'

    let fname = g:utils.menucmd({
        \ 'limit': 100,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': ':'.a:cmd.' buffer'
    \ }).pipe_from(entriescmd).input(execute('silent ls')).output()

    if empty(fname)
        return
    endif

    execute a:cmd . " " . fname
endfunction

function! g:fuzzy.openold(cmd)
    let entriescmd = 'grep "."' .
        \ ' | grep -v "term://"' .
        \ ' | grep -v ".git/"' .
        \ ' | grep -v "/tmp/nvim"' .
        \ ' | cut -d":" -f2- | sed "s/^\s\+//"'

    let fname = g:utils.menucmd({
        \ 'limit': 100,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': ':'.a:cmd.' old file'
    \ }).pipe_from(entriescmd).input(execute('silent oldfiles')).output()

    if empty(fname)
        return
    endif

    execute a:cmd . " " . fname
endfunction

function! s:project_root_info(dirname)
    let dirname = substitute(a:dirname, '\.git\/\/', '.git/', '')
    let toplevel = g:utils.project_root(dirname)
    let filescmd = g:utils.project_files_cmd(dirname)

    if match(dirname, '^fugitive:\/\/') == 0
        let initial = split(dirname, '\/\.git\/\?[a-fA-F0-9]\{40\}\/')[-1]
    else
        let initial = g:utils.relativepath(toplevel, dirname)
    end

    if !empty(initial)
        let initial = initial . '/'
    endif

    return {
        \ 'initial': initial,
        \ 'toplevel': toplevel,
        \ 'filescmd': filescmd
    \ }
endfunction

function! s:gather_dirs(root, maxdepth, ...)
    let root = substitute(resolve(a:root), '/$', '', '')

    if a:0 != 0
        let options = a:1
        if !has_key(options, 'self')
            let options.self = 1
        endif
        if !has_key(options, 'parent')
            let options.parent = 1
        endif
    else
        let options = { 'self': 1, 'parent': 1 }
    endif

    let firstentries = []

    if options.parent
        let firstentries = add(firstentries, '../')
    endif

    if options.self
        let firstentries = add(firstentries, './')
    endif

    let entriescmd = 'cd ' . shellescape(root) . '; and find -L . '

    if a:maxdepth >= 0
        let entriescmd = entriescmd . '-maxdepth ' . a:maxdepth . ' '
    endif

    let finalcmd = entriescmd .
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
        \ 'sed "/^\.\$/d" |' .
        \ 'sort -u | ' .
        \ 'sed "s/^\.\///" | sed "s/\$/\//"'

    if !empty(firstentries)
        call map(firstentries, '"(echo \"" . v:val . "\" | psub)"')
        let finalcmd = 'cat ' . join(firstentries, ' ') . ' (' . finalcmd . ' | psub)'
    endif

    return finalcmd
endfunction

function! s:getparent(dirname)
    py import os.path, vim
    return '/' . pyeval("os.path.join(*vim.eval('a:dirname').split(os.path.sep)[:-1])")
endfunction
