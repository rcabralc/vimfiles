" Based on the original TextMate's Monokai theme and technique somewhat based
" on altercation/solarized.

" Palette
let s:black      = "#000000"
let s:darkgray4  = "#101010"
let s:darkgray3  = "#202020"
let s:darkgray2  = "#303030"
let s:darkgray1  = "#404040"
let s:darkgray0  = "#505050"
let s:lightgray0 = "#707070"
let s:lightgray1 = "#909090"
let s:lightgray2 = "#b0b0b0"
let s:lightgray3 = "#d0d0d0"
let s:white      = "#ffffff"

" Terminal versions
let s:tblack      = 16
let s:tdarkgray4  = 233
let s:tdarkgray3  = 234
let s:tdarkgray2  = 236
let s:tdarkgray1  = 238
let s:tdarkgray0  = 239
let s:tlightgray0 = 242
let s:tlightgray1 = 246
let s:tlightgray2 = 145
let s:tlightgray3 = 252
let s:twhite      = 231

hi clear
if exists("syntax on")
    syntax reset
endif
let g:colors_name = "unpigmented"

" For relevant help:
" :help highlight-groups
" :help cterm-colors
" :help group-name

" For testing:
" :source $VIMRUNTIME/syntax/hitest.vim


exe "hi! Normal         ctermfg=".s:twhite     ." ctermbg=".s:tdarkgray4 ." cterm=NONE              guifg=".s:white     ." guibg=".s:darkgray4 ." gui=NONE"

exe "hi! Comment        ctermfg=".s:tdarkgray1 ." ctermbg=NONE"          ." cterm=NONE              guifg=".s:darkgray1 ." guibg=NONE             gui=NONE"
"       *Comment        any comment

exe "hi! Constant       ctermfg=".s:tlightgray2." ctermbg=NONE              cterm=NONE              guifg=".s:lightgray2." guibg=NONE             gui=NONE"
"       *Constant       any constant
"        String         a string constant: "this is a string"
"        Character      a character constant: 'c', '\n'
"        Number         a number constant: 234, 0xff
"        Boolean        a boolean constant: TRUE, false
"        Float          a floating point constant: 2.3e10
exe "hi! Boolean        ctermfg=".s:twhite     ." ctermbg=NONE              cterm=NONE              guifg=".s:white     ." guibg=NONE             gui=NONE"

exe "hi! Identifier     ctermfg=".s:tlightgray3." ctermbg=NONE              cterm=NONE              guifg=".s:lightgray3." guibg=NONE             gui=NONE"
"       *Identifier     any variable name
"        Function       function name (also: methods for classes)

exe "hi! Statement      ctermfg=".s:twhite     ." ctermbg=NONE              cterm=NONE              guifg=".s:white     ." guibg=NONE             gui=NONE"
"       *Statement      any statement
"        Conditional    if, then, else, endif, switch, etc.
"        Repeat         for, do, while, etc.
"        Label          case, default, etc.
"        Operator       "sizeof", "+", "*", etc.
"        Keyword        any other keyword
"        Exception      try, catch, throw
exe "hi! Operator       ctermfg=".s:twhite     ." ctermbg=NONE              cterm=NONE              guifg=".s:white     ." guibg=NONE             gui=NONE"

exe "hi! PreProc        ctermfg=".s:tlightgray0." ctermbg=NONE              cterm=bold              guifg=".s:lightgray0." guibg=NONE             gui=bold"
"       *PreProc        generic Preprocessor
"        Include        preprocessor #include
"        Define         preprocessor #define
"        Macro          same as Define
"        PreCondit      preprocessor #if, #else, #endif, etc.

exe "hi! Type           ctermfg=".s:twhite     ." ctermbg=NONE              cterm=bold              guifg=".s:white     ." guibg=NONE             gui=bold"
"       *Type           int, long, char, etc.
"        StorageClass   static, register, volatile, etc.
"        Structure      struct, union, enum, etc.
"        Typedef        A typedef

exe "hi! Special        ctermfg=".s:tlightgray0." ctermbg=NONE              cterm=bold              guifg=".s:lightgray0." guibg=NONE             gui=bold"
"       *Special        any special symbol
"        SpecialChar    special character in a constant
"        Tag            you can use CTRL-] on this
"        Delimiter      character that needs attention
"        SpecialComment special things inside a comment
"        Debug          debugging statements

exe "hi! Underlined     ctermfg=NONE              ctermbg=NONE              cterm=underline         guifg=NONE             guibg=NONE              gui=underline"
"       *Underlined     text that stands out, HTML links

exe "hi! Ignore         ctermfg=NONE              ctermbg=NONE              cterm=NONE              guifg=NONE             guibg=NONE              gui=NONE"
"       *Ignore         left blank, hidden |hl-Ignore|

exe "hi! Error          ctermfg=".s:twhite     ." ctermbg=NONE              cterm=bold,reverse      guifg=".s:white     ." guibg=NONE              gui=bold,reverse"
"       *Error          any erroneous construct

exe "hi! Todo           ctermfg=".s:twhite     ." ctermbg=NONE              cterm=bold              guifg=".s:white     ." guibg=NONE              gui=bold"
"       *Todo           anything that needs extra attention; mostly the
"                       keywords TODO FIXME and XXX


" Extended highlighting
exe "hi! SpecialKey     ctermfg=".s:tlightgray0." ctermbg=NONE              cterm=NONE              guifg=".s:lightgray0." guibg=NONE             gui=NONE"
exe "hi! NonText        ctermfg=".s:tdarkgray3 ." ctermbg=NONE              cterm=NONE              guifg=".s:darkgray3 ." guibg=NONE             gui=NONE"
exe "hi! StatusLine     ctermfg=".s:tblack     ." ctermbg=".s:tlightgray3." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray3." gui=NONE"
exe "hi! StatusLineNC   ctermfg=".s:tdarkgray2 ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray0." gui=NONE"
exe "hi! Visual         ctermfg=NONE              ctermbg=".s:tdarkgray3 ." cterm=NONE              guifg=NONE             guibg=".s:darkgray3 ." gui=NONE"
exe "hi! Directory      ctermfg=".s:tdarkgray0 ." ctermbg=NONE              cterm=NONE              guifg=".s:darkgray0 ." guibg=NONE             gui=NONE"
exe "hi! ErrorMsg       ctermfg=".s:twhite     ." ctermbg=".s:tdarkgray0 ." cterm=bold              guifg=".s:white     ." guibg=".s:darkgray0 ." gui=bold"
exe "hi! IncSearch      ctermfg=".s:tblack     ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray0." gui=NONE"
exe "hi! Search         ctermfg=NONE              ctermbg=NONE              cterm=underline         guifg=NONE             guibg=NONE             gui=underline"
exe "hi! MoreMsg        ctermfg=".s:tblack     ." ctermbg=".s:tdarkgray0 ." cterm=NONE              guifg=".s:black     ." guibg=".s:darkgray0 ." gui=NONE"
exe "hi! ModeMsg        ctermfg=".s:tlightgray0." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:lightgray0." guibg=".s:black     ." gui=NONE"
exe "hi! LineNr         ctermfg=".s:tdarkgray2 ." ctermbg=".s:tdarkgray4 ." cterm=NONE              guifg=".s:darkgray2 ." guibg=".s:darkgray4 ." gui=NONE"
exe "hi! Question       ctermfg=".s:tlightgray3." ctermbg=NONE              cterm=bold              guifg=".s:lightgray3." guibg=NONE             gui=bold"
exe "hi! VertSplit      ctermfg=".s:tdarkgray4 ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:darkgray4 ." guibg=".s:lightgray0." gui=NONE"
exe "hi! Title          ctermfg=".s:twhite     ." ctermbg=NONE              cterm=bold              guifg=".s:white     ." guibg=NONE             gui=bold"
exe "hi! VisualNOS      ctermfg=NONE              ctermbg=".s:tdarkgray3 ." cterm=standout          guifg=NONE             guibg=".s:darkgray3 ." gui=standout"
exe "hi! WarningMsg     ctermfg=".s:tblack     ." ctermbg=".s:tlightgray0." cterm=bold              guifg=".s:black     ." guibg=".s:lightgray0." gui=bold"
exe "hi! WildMenu       ctermfg=".s:tlightgray3." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:lightgray3." guibg=".s:black     ." gui=NONE"
exe "hi! Folded         ctermfg=".s:tdarkgray1 ." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:darkgray1 ." guibg=".s:black     ." gui=NONE"
exe "hi! FoldColumn     ctermfg=".s:tdarkgray1 ." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:darkgray1 ." guibg=".s:black     ." gui=NONE"
exe "hi! DiffAdd        ctermfg=".s:tblack     ." ctermbg=".s:tlightgray3." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray3." gui=NONE"
exe "hi! DiffChange     ctermfg=".s:tblack     ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray0." gui=NONE"
exe "hi! DiffDelete     ctermfg=".s:twhite     ." ctermbg=".s:tdarkgray1 ." cterm=NONE              guifg=".s:black     ." guibg=".s:darkgray1 ." gui=NONE"
exe "hi! DiffText       ctermfg=".s:tblack     ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:black     ." guibg=".s:lightgray0." gui=NONE"
exe "hi! SignColumn     ctermfg=".s:tlightgray2." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:lightgray2." guibg=".s:black     ." gui=NONE"
exe "hi! Conceal        ctermfg=".s:tdarkgray4 ." ctermbg=NONE              cterm=NONE              guifg=".s:darkgray4 ." guibg=NONE             gui=NONE"
exe "hi! SpellBad       ctermfg=NONE              ctermbg=NONE              cterm=NONE              guifg=NONE             guibg=NONE             gui=undercurl guisp=".s:white
exe "hi! SpellCap       ctermfg=NONE              ctermbg=NONE              cterm=NONE              guifg=NONE             guibg=NONE             gui=undercurl guisp=".s:lightgray1
exe "hi! SpellRare      ctermfg=NONE              ctermbg=NONE              cterm=NONE              guifg=NONE             guibg=NONE             gui=undercurl guisp=".s:darkgray0
exe "hi! SpellLocal     ctermfg=NONE              ctermbg=NONE              cterm=NONE              guifg=NONE             guibg=NONE             gui=undercurl guisp=".s:lightgray1
exe "hi! Pmenu          ctermfg=".s:tdarkgray3 ." ctermbg=".s:tlightgray0." cterm=NONE              guifg=".s:darkgray3 ." guibg=".s:lightgray0." gui=NONE"
exe "hi! PmenuSel       ctermfg=".s:twhite     ." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:white     ." guibg=".s:black     ." gui=NONE"
exe "hi! PmenuSbar      ctermfg=NONE              ctermbg=".s:tdarkgray2 ." cterm=NONE              guifg=NONE             guibg=".s:darkgray2 ." gui=NONE"
exe "hi! PmenuThumb     ctermfg=NONE              ctermbg=".s:twhite     ." cterm=NONE              guifg=NONE             guibg=".s:white     ." gui=NONE"
exe "hi! TabLine        ctermfg=".s:tlightgray0." ctermbg=".s:tblack     ." cterm=bold              guifg=".s:lightgray0." guibg=".s:black     ." gui=bold"
exe "hi! TabLineFill    ctermfg=".s:tblack     ." ctermbg=".s:tblack     ." cterm=NONE              guifg=".s:black     ." guibg=".s:black     ." gui=NONE"
exe "hi! TabLineSel     ctermfg=".s:twhite     ." ctermbg=".s:tdarkgray2 ." cterm=bold              guifg=".s:white     ." guibg=".s:darkgray2 ." gui=bold"
exe "hi! CursorColumn   ctermfg=NONE              ctermbg=".s:tdarkgray3 ." cterm=NONE              guifg=NONE             guibg=".s:darkgray3 ." gui=NONE"
exe "hi! CursorLine     ctermfg=NONE              ctermbg=".s:tdarkgray3 ." cterm=NONE              guifg=NONE             guibg=".s:darkgray3 ." gui=NONE"
exe "hi! CursorLineNr   ctermfg=".s:tlightgray0." ctermbg=".s:tdarkgray4 ." cterm=NONE              guifg=".s:lightgray0." guibg=".s:darkgray4 ." gui=NONE"
exe "hi! ColorColumn    ctermfg=NONE              ctermbg=".s:tblack     ." cterm=NONE              guifg=NONE             guibg=".s:black     ." gui=NONE"
exe "hi! Cursor         ctermfg=".s:tblack     ." ctermbg=".s:twhite     ." cterm=NONE              guifg=".s:black      " guibg=".s:white     ." gui=NONE"
hi! link lCursor Cursor
exe "hi! MatchParen     ctermfg=NONE              ctermbg=NONE              cterm=reverse,underline guifg=NONE             guibg=NONE             gui=reverse,underline"

" Optimizations
hi! link javaScriptFuncExp  Normal

" Must be at the end, because of ctermbg=234 bug.
" https://groups.google.com/forum/#!msg/vim_dev/afPqwAFNdrU/nqh6tOM87QUJ
set background=dark
