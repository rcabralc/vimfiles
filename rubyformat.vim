let g:rubyformat = {}
let s:formatprg = 'bundle exec rubocop --except Lint/Debugger,Style/SymbolProc -ao /dev/null -s - | tail -n+2'

function! rubyformat.format()
    if exists('b:dont_format') && b:dont_format
        return
    endif

    if expand('%:t') == 'schema.rb'
        return
    endif

    let oldsyntax = &syntax
    call g:utils.format(s:formatprg)
    let &syntax = oldsyntax
endfunction
