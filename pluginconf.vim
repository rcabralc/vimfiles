" Editorconfig
" ============

let g:EditorConfig_exclude_patterns = ['scp://.*']

" Colorscheme
" ===========

set background=dark
try
  colorscheme undefined
catch /^Vim\%((\a\+)\)\=:E185/ " catch missing colorscheme
endtry


" ALE
" ===

let g:ale_sign_error = "\u2717"
let g:ale_sign_warning = "\u26A0"
let g:ale_statusline_format = ['%d error(s)', '%d warning(s)', '']
let g:ale_lint_on_save = 0
let g:ale_fix_on_save = 1
let g:ale_history_enabled = 0
let g:ale_linters = { 'ruby': ['rubocop'] }
let g:ale_fixers = { 'ruby': ['rubocop'], 'javascript': ['eslint'] }
let g:ale_ruby_rubocop_options = '--except Lint/Debugger,Style/SymbolProc'
let g:ale_pattern_options = {
\   'db/schema\.rb$': { 'ale_enabled': 0 },
\ }


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

let g:polyglot_disabled = ['javascript', 'ruby']


" Rest console
" ============

let g:vrc_trigger = '<Leader>r'
let g:vrc_set_default_mapping = 0
let g:vrc_include_response_header = 1
let g:vrc_show_command = 1


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

inoremap <silent><expr> <C-n> deoplete#manual_complete()
inoremap <silent><expr> <C-p> deoplete#manual_complete()


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


" Multiple cursors
" ================

let g:multi_cursor_exit_from_visual_mode = 0

" Called once right before you start selecting multiple cursors
function! Multiple_cursors_before()
    if exists('g:deoplete#disable_auto_complete') 
       let g:deoplete#disable_auto_complete = 1
    endif
endfunction

" Called once only when the multiple selection is canceled (default <Esc>)
function! Multiple_cursors_after()
    if exists('g:deoplete#disable_auto_complete')
       let g:deoplete#disable_auto_complete = 0
    endif
endfunction


" Not sure why vimgrep doesn't work (this requires ag installed, no support for
" multilne).
let g:far#source = 'ag'
