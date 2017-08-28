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
    \ 'right': [ [ 'ale', 'lineinfo' ],
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
    \ 'ale': 'ALEGetStatusLine',
\ }
let g:lightline.component_type = {
    \ 'ale': 'error',
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


" ALE
" ===

set statusline+=%#warningmsg#
set statusline+=%{ALEGetStatusLine()}
set statusline+=%*

let g:ale_sign_error = "\u2717"
let g:ale_sign_warning = "\u26A0"
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']
let g:ale_lint_on_save = 0

let g:ale_linters = { 'ruby': ['rubocop'] }

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
" let g:ruby_no_expensive = 1
let g:ruby_minlines = 200
let g:ruby_spellcheck_strings = 1

" Ruby filetype options.
let g:ruby_indent_access_modifier_style = 'outdent'
let g:ruby_indent_block_style = 'do'

let g:polyglot_disabled = ['ruby']


" Rest console
" ============

let g:vrc_trigger = '<Leader>r'
let g:vrc_set_default_mapping = 0
let g:vrc_include_response_header = 1
let g:vrc_show_command = 1


" dbext
" =====

let g:dbext_default_window_use_horiz = 1
let g:dbext_default_window_width = ''


" Indent line
" ===========

let g:indentLine_char = '┆'
let g:indentLine_setColors = 0


" Incsearch and asterisk
" ======================

let g:incsearch#auto_nohlsearch = 1
let g:asterisk#keeppos = 1


" Deoplete
" ========
let g:deoplete#enable_at_startup = 1


" Table mode
" ==========

function! s:isAtStartOfLine(mapping)
  let text_before_cursor = getline('.')[0 : col('.')-1]
  let mapping_pattern = '\V' . escape(a:mapping, '\')
  let comment_pattern = '\V' . escape(substitute(&l:commentstring, '%s.*$', '', ''), '\')
  return (text_before_cursor =~? '^' . ('\v(' . comment_pattern . '\v)?') . '\s*\v' . mapping_pattern . '\v$')
endfunction

inoreabbrev <expr> <bar><bar>
          \ <SID>isAtStartOfLine('\|\|') ?
          \ '<c-o>:TableModeEnable<cr><bar><space><bar><left><left>' : '<bar><bar>'
inoreabbrev <expr> __
          \ <SID>isAtStartOfLine('__') ?
          \ '<c-o>:silent! TableModeDisable<cr>' : '__'


" GitGutter
" =========

let g:gitgutter_grep_command = 'grep'


" Expand region
" =============

let g:expand_region_text_objects_ruby = {
      \ 'im' :0,
      \ 'am' :0
\ }
