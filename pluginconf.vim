" Editorconfig
" ============

let g:EditorConfig_exclude_patterns = ['scp://.*']

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
    \           [ 'readonly', 'filename', 'modified' ] ],
    \ 'right': [ [ 'syntastic', 'lineinfo' ],
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


" Syntastic
" =========

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_wq = 0

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

" Rest console
" ============

let g:vrc_trigger = '<Leader>r'
