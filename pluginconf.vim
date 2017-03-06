" Editorconfig
" ============

let g:EditorConfig_exclude_patterns = ['scp://.*']

" Colorscheme
" ===========

set background=dark
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
let g:syntastic_check_on_wq = 0
let g:syntastic_error_symbol = "\u2717"
let g:syntastic_warning_symbol = "\u26A0"

let g:syntastic_javascript_checkers = ['jshint', 'jscs']
let g:syntastic_python_checkers = ['flake8']
let g:syntastic_ruby_checkers = ['rubocop']
let g:syntastic_ruby_rubocop_args = '-D'
let g:syntastic_eruby_ruby_quiet_messages =
    \ {'regex': 'possibly useless use of \(a variable\|+\) in void context'}


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
let g:ruby_minlines = 200

" Ruby filetype options.
let g:ruby_indent_access_modifier_style = 'outdent'
let g:ruby_indent_block_style = 'do'

let g:polyglot_disabled = ['ruby']


" Git Gutter
" ==========

" vim-gitgutter: enable/disable line hightlighting
nmap <Leader>h <Plug>GitGutterLineHighlightsToggle
" vim-gitgutter: next/previous hunks
nmap <Leader>[ <Plug>GitGutterPrevHunk
nmap <Leader>] <Plug>GitGutterNextHunk


" Rest console
" ============

let g:vrc_trigger = '<Leader>r'


" Deoplete
" ========

let g:deoplete#enable_at_startup = 1


" dbext
" =====

let g:dbext_default_window_use_horiz = 0
let g:dbext_default_window_width = ''

let g:dbext_default_profile_biva_dev = 'type=PGSQL:user=rafael.coutinho:dbname=Biva_development'
let g:dbext_default_profile_biva_prd = 'type=PGSQL:user=rafael.coutinho:host=biva-prd.cqn9p6dhfew8.us-east-1.rds.amazonaws.com:dbname=biva'


" Indent line
" ===========

let g:indentLine_char = '│'
let g:indentLine_setColors = 0
