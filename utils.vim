" This file defines a bunch of utility functions, grouped in a single
" namespace: g:utils.
let g:utils = {}

function! utils.gitroot(file)
    return g:utils.fish('git rev-parse --show-toplevel', {
        \ 'cwd': fnamemodify(a:file, ':p:h'),
        \ 'error': '/dev/null',
        \ 'chomp': 1
    \ })
endfunction

function! utils.project_files_cmd(file)
    let gitroot = g:utils.gitroot(a:file)

    if !empty(gitroot)
        return g:utils.fish(
            \ 'git ls-files -co --exclude-standard | sort -u', {
            \ 'cwd': gitroot,
            \ 'cmd': 1
            \ }
        \ )
    endif

    return g:utils.fish(
        \ 'ag . -i --nocolor --nogroup --hidden '.
        \ '--depth 3'.
        \ '--ignore .git '.
        \ '--ignore .hg '.
        \ '--ignore .DS_Store '.
        \ '--ignore "*.swp" '.
        \ '-g "" ', {
        \ 'error': '/dev/null',
        \ 'cwd': g:utils.project_root(a:file),
        \ 'cmd': 1
        \ }
    \ )
endfunction

" Give the "project root" of the given file/dir (use a full path).
function utils.project_root(file)
    let gitroot = g:utils.gitroot(a:file)

    if empty(gitroot)
        return fnamemodify(a:file, ':p:h')
    endif

    return gitroot
endfunction

function! utils.vimsource(filename)
    execute 'source ' . fnamemodify($MYVIMRC, ':p:h') . '/' . a:filename
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
        exe 'set shell=' . previous_shell

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
