let g:gitcommand = {}

function! g:gitcommand.select_branch(root, ...)
    let options = a:0 ? a:1 : {}
    let title = has_key(options, 'title') ? options.title : 'Select Git branch'

    let branchescmd = 'git branch --list -a --no-color | ' .
        \ "grep -v HEAD | grep -v '\*'"
    let entriescmd = g:utils.fish(branchescmd, { 'cwd': a:root, 'cmd': 1 })

    return g:utils.spawn_menu(entriescmd, {
        \ 'limit': 20,
        \ 'word_delimiters': '/',
        \ 'completion_sep': '/',
        \ 'title': title
    \ })
endfunction

function! g:gitcommand.checkout()
    let filename = expand('%:p')
    let root = g:utils.gitroot(filename)
    if empty(root)
        return
    endif

    call g:utils.fish('git fetch', { 'cwd': root })

    let branch = g:gitcommand.select_branch(root, {
        \ 'title': 'Select Git branch for checkout'
    \ })

    if empty(branch)
        return
    endif

    let branch = substitute(branch, '^remotes\/origin\/', '', '')
    call g:utils.fish('git checkout '.branch, { 'cwd': root })
endfunction
