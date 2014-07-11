fun! <SID>softmotion(motion)
    let oldisk = &isk
    execute "setlocal isk=".substitute(oldisk, '_,', '', 'g')
    execute "normal ".a:motion
    execute "setlocal isk=".oldisk
endfun

map <A-b> :call <SID>softmotion('b')<CR>
map <A-w> :call <SID>softmotion('w')<CR>
map <A-e> :call <SID>softmotion('e')<CR>
