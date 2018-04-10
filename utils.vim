" This file defines a bunch of utility functions, grouped in a single
" namespace: g:utils.
let g:utils = {}

function! utils.gitroot(file)
    if match(a:file, '^fugitive:\/\/') == 0
        return substitute(split(a:file, '/\.git/')[0], '^fugitive:\/\/', '', '')
    endif

    let root = g:utils.fish('/usr/bin/git rev-parse --show-toplevel', {
        \ 'cwd': fnamemodify(a:file, ':p:h'),
        \ 'error': '/dev/null',
        \ 'chomp': 1
    \ })

    if empty(root)
      return ''
    endif

    let file = g:utils.relativepath(root, a:file)

    let is_not_tracked = g:utils.fish('git ls-files ' . file . ' --error-unmatch >/dev/null 2>/dev/null; echo $status', {
        \ 'cwd': root,
        \ 'chomp': 1
    \ })

    if is_not_tracked ==# '1'
      return ''
    end

    return root
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

    if g:utils.looks_like_gitroot(root)
        return g:utils.fish(
            \ 'git ls-files -co --exclude-standard | sort -u', {
            \ 'cwd': root,
            \ 'cmd': 1
            \ }
        \ )
    elseif s:looks_like_gemroot(root)
        return g:utils.fish(
            \ 'ag . -i --nocolor --nogroup --hidden -g ""', {
            \ 'error': '/dev/null',
            \ 'cwd': root,
            \ 'cmd': 1
            \ }
        \ )
    endif

    return g:utils.fish('ls -ap1 | sed "/^\.\/\$/d"', {
        \ 'error': '/dev/null',
        \ 'cwd': root,
        \ 'cmd': 1
        \ }
    \ )
endfunction

" Give the "project root" of the given file/dir (use a full path).
function utils.project_root(file)
    let gitroot = g:utils.gitroot(a:file)
    if !empty(gitroot)
        return gitroot
    endif

    let gemroot = s:gemroot(a:file)
    if !empty(gemroot)
        return gemroot
    endif

    return fnamemodify(a:file, ':p:h')
endfunction

function! g:utils.rubygems_path(dirname)
    let gemroot = s:gemroot(a:dirname)
    if !empty(gemroot)
        return s:parent_dir(gemroot)
    endif
    return g:utils.fish(
        \ 'rbenv exec bundle env | grep "Gem Path" | xargs | cut -d" " -f3- | cut -d: -f2', {
        \ 'cwd': a:dirname,
        \ 'chomp': 1
        \ }
    \).'/gems'
endfunction

function! s:gemroot(file)
    let dirname = fnamemodify(a:file, ':p:h')

    while dirname != '/'
        if s:looks_like_gemroot(dirname)
            return dirname
        endif

        let dirname = s:parent_dir(dirname)
    endwhile

    return ''
endfunction

function! s:parent_dir(dirname)
    return fnamemodify(a:dirname . '-as-if-not-dir', ':p:h')
endfunction

function! s:looks_like_gemroot(dirname)
    return match(a:dirname, 'lib\/ruby\/gems\/\d\.\d\.\d\/gems\/' . fnamemodify(a:dirname, ':t') . '$') >= 0
endfunction

function! utils.looks_like_gitroot(dirname)
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
        if has_key(options, 'input')
          let output = system(l:command, options.input)
        else
          let output = system(l:command)
        endif
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
    let path = substitute(resolve(a:path), '/$', '', '')
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

function! utils.menucmd(params)
    let menucmd = 'pickout --daemonize'

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

    return g:utils.fishline.wrap(menucmd).options({ 'chomp': 1, 'error': '/tmp/debug.log' })
endfunction

let utils.fishline = {}

function! utils.fishline.wrap(ob)
    if type(a:ob) ==# 1
        return s:build_fishline(a:ob)
    endif
    return a:ob
endfunction

function! s:build_fishline(cmd, ...)
    if a:0
        let initial_values = a:1
    else
        let initial_values = {}
    endif

    let new_fishline = { '_cmd': a:cmd }

    if has_key(initial_values, '_options')
      let new_fishline._options = initial_values._options
    else
      let new_fishline._options = {}
    endif

    let new_fishline.pipe_to = function('s:fishline_pipe_to')
    let new_fishline.pipe_from = function('s:fishline_pipe_from')
    let new_fishline.options = function('s:fishline_options')
    let new_fishline.input = function('s:fishline_input')
    let new_fishline.output = function('s:fishline_output')

    return new_fishline
endfunction

function! s:fishline_pipe_to(command) dict
    let cmd = self._cmd
    let othercmd = type(a:command) ==# 1 ? a:command : a:command._cmd
    return s:build_fishline(cmd.' | '.othercmd, self)
endfunction

function! s:fishline_pipe_from(command) dict
    let othercmd = self._cmd
    let cmd = type(a:command) ==# 1 ? a:command : a:command._cmd
    return s:build_fishline(cmd.' | '.othercmd, self)
endfunction

function! s:fishline_options(options) dict
    let new_fishline = s:build_fishline(self._cmd, self)
    if has_key(a:options, 'cwd')
        let new_fishline._options.cwd = a:options.cwd
    endif
    if has_key(a:options, 'error')
        let new_fishline._options.error = a:options.error
    endif
    if has_key(a:options, 'chomp')
        let new_fishline._options.chomp = a:options.chomp
    endif
    return new_fishline
endfunction

function! s:fishline_input(input) dict
    let new_fishline = s:build_fishline(self._cmd, self)
    let new_fishline._options.input = a:input
    return new_fishline
endfunction

function! s:fishline_output() dict
    return g:utils.fish(self._cmd, self._options)
endfunction
