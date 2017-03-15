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
