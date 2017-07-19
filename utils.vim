" This file defines a bunch of utility functions, grouped in a single
" namespace: g:utils.
let g:utils = {}

function! utils.gitroot(file)
    if match(a:file, '^fugitive:\/\/') == 0
        return substitute(split(a:file, '/\.git/')[0], '^fugitive:\/\/', '', '')
    endif

    return g:utils.fish('git rev-parse --show-toplevel', {
        \ 'cwd': fnamemodify(a:file, ':p:h'),
        \ 'error': '/dev/null',
        \ 'chomp': 1
    \ })
endfunction

function! utils.project_files_cmd(file, ...)
    if a:0
        let options = a:1
    else
        let options = {}
    endif

    if has_key(options, 'is_root') && options.is_root
        let root = fnamemodify(a:file, ':p:h')
    else
        let root = g:utils.project_root(a:file)
    endif

    if s:looks_like_gitroot(root)
        return g:utils.fish(
            \ 'git ls-files -co --exclude-standard | sort -u', {
            \ 'cwd': root,
            \ 'cmd': 1
            \ }
        \ )
    endif

    if s:looks_like_gemroot(root)
        let options.depth = -1
    elseif !has_key(options, 'depth')
        let options.depth = 3
    endif

    return g:utils.fish(
        \ 'ag . -i --nocolor --nogroup --hidden '.
        \ '--depth '. options.depth.
        \ '--ignore .git '.
        \ '--ignore .hg '.
        \ '--ignore .DS_Store '.
        \ '--ignore "*.swp" '.
        \ '-g "" ', {
        \ 'error': '/dev/null',
        \ 'cwd': root,
        \ 'cmd': 1
        \ }
    \ )
endfunction

" Give the "project root" of the given file/dir (use a full path).
function utils.project_root(file)
    let gemroot = s:gemroot(a:file)
    if !empty(gemroot)
        return gemroot
    endif

    let gitroot = g:utils.gitroot(a:file)
    if !empty(gitroot)
        return gitroot
    endif

    return fnamemodify(a:file, ':p:h')
endfunction

function! s:gemroot(file)
    let dirname = fnamemodify(a:file, ':p:h')

    while dirname != '/'
        if s:looks_like_gemroot(dirname)
            return dirname
        endif

        let dirname = fnamemodify(dirname . '-as-if-not-dir', ':p:h')
    endwhile

    return ''
endfunction

function! s:looks_like_gemroot(dirname)
    if match(a:dirname, 'lib\/ruby\/gems\/\d\.\d\.\d\/gems\/' . fnamemodify(a:dirname, ':t') . '$') >= 0
        return 1
    endif

    let tail = split(a:dirname, '/')[-1]

    if match(tail, "-")
        let tail = join(split(tail, '-')[0:-2], '-')
    endif

    return filereadable(a:dirname . '/' . tail . '.gemspec') ||
                \ filereadable(a:dirname . '/README') ||
                \ filereadable(a:dirname . '/README.md') ||
                \ filereadable(a:dirname . '/README.rdoc')
endfunction

function! s:looks_like_gitroot(dirname)
    return filereadable(a:dirname . '/.git/config') || filereadable(a:dirname . '/.git')
endfunction

function! utils.vimsource(filename)
    try
        execute 'source ' . fnamemodify($MYVIMRC, ':p:h') . '/' . a:filename
    catch /^Vim\%((\a\+)\)\=:E484/ " E484 is Can't open <file>
        return
    endtry
endfunction

" Strip the newline from the end of a string
function! utils.chomp(str)
    return substitute(a:str, '\n$', '', '')
endfunction

" Run a command in fish shell.
function! utils.fish(command, ...)
    let l:command = a:command

    if a:0
        let options = a:1
    else
        let options = {}
    endif

    if has_key(options, 'cwd')
        let l:command = 'cd ' . shellescape(options.cwd) . '; and ' . l:command
    endif

    if has_key(options, 'error')
        let l:command = l:command . ' 2>' . options.error
    endif

    if has_key(options, 'cmd')
        let output = l:command
    else
        let previous_shell = &shell

        set shell=/usr/bin/fish
        let output = system(l:command)
        let &shell = previous_shell

        if v:shell_error
            return ''
        end
    end

    if has_key(options, 'chomp') && options.chomp
        let output = g:utils.chomp(output)
    endif

    return output
endfunction

function! utils.relativepath(basepath, path)
    let basepath = substitute(resolve(a:basepath), '/$', '', '')
    let basepath = substitute(basepath, '^/files/rcabralc', '/home/rcabralc', '')
    let path = substitute(resolve(a:path), '/$', '', '')
    let path = substitute(path, '^/files/rcabralc', '/home/rcabralc', '')
    let rel = substitute(path, '^' . g:utils.regexescape(basepath), '', '')
    return substitute(rel, '^/', '', '')
endfunction

function! utils.makepath(file)
    let dir = fnamemodify(a:file, ":p:h")
    if !isdirectory(dir)
        call mkdir(dir, "p")
    endif
    return a:file
endfunction

" Borrowed from somewhere in Internet, lost reference...
function! utils.regexescape(str)
  let str = a:str

  if exists('+ssl') && !&ssl
    let str = escape(str, '\')
  en

  for each in ['^', '$', '.']
    let str = escape(str, each)
  endfo

  return str
endfunction

function! utils.spawn_menu(entriescmd, params)
    if exists('g:python3_executable')
        let executable = g:python3_executable
    else
        let executable = 'python'
    endif

    let menucmd = executable . ' -u ' . g:vimdir . 'python/menu.py --daemonize'

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

" Some code borrowed from rust.vim.
function! utils.format(formatprg, ...)
    let intmpname = expand("%:p:h") . "/." . expand("%:p:t") . ".fmt.in"
    let outtmpname = expand("%:p")
    call writefile(getline(1, '$'), intmpname)
    let command = 'cat ' . shellescape(intmpname) . ' | ' . a:formatprg . ' > ' . shellescape(outtmpname)

    if a:0
        let dirname = a:1
    else
        let dirname = expand("%:p:h")
    endif

    if !empty(dirname)
        let command = 'cd ' . dirname . ' && ' . command
    endif

    if exists("*systemlist")
        let out = systemlist(command)
    else
        let out = split(system(command), '\r\?\n')
    endif

    if v:shell_error == 0
        let curw = winsaveview()
        " Remove undo point caused by BufWritePre
        try | silent undojoin | catch | endtry

        " Reload
        silent edit!

        call winrestview(curw)
    else
        echoerr out
    endif

    call delete(intmpname)
endfunction
