" Vim color scheme
"
" Name:        rafael.vim
" Maintainer:  Rafael Cabral Coutinho <rcabralc@gmail.com> 
" License:     public domain
"
" A GUI color scheme based on railscasts and zmrok.

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "rafael"


" Normal and NonText definition
" -----------------------------

hi Normal           guifg=#F8F8F8 guibg=#0D0D09
hi NonText          guifg=#888888 guibg=#080808
if exists("transparent_background") && transparent_background == 1
  hi Normal                         ctermbg=NONE
  hi NonText          ctermfg=246   ctermbg=NONE
else
  hi Normal                         ctermbg=233
  hi NonText          ctermfg=246   ctermbg=232
end


" Window elements
" ---------------

hi Cursor           guifg=Black   guibg=#FFFFFF
hi Cursor           ctermfg=0     ctermbg=15
hi CursorLine                     guibg=#141414 gui=none
hi CursorLine                     ctermbg=233   cterm=none
hi CursorColumn                   guibg=#141414
hi CursorColumn                   ctermbg=233
hi DiffAdd          guifg=#E6E1DC guibg=#144212
hi DiffAdd          ctermfg=230   ctermbg=22
hi DiffDelete       guifg=#E6E1DC guibg=#660000
hi DiffDelete       ctermfg=230   ctermbg=52
hi Directory        guifg=#A5C261               gui=none
hi Directory        ctermfg=106                 cterm=none
hi Folded           guifg=#F6F3E8 guibg=#444444 gui=none
hi Folded           ctermfg=255   ctermbg=237   cterm=none
hi LineNr           guifg=#888888 guibg=Black
hi LineNr           ctermfg=241   ctermbg=0
hi Pmenu            guifg=#141414 guibg=#CDA869
hi Pmenu            ctermfg=233   ctermbg=179
hi PmenuSbar                      guibg=#DAEFA3
hi PmenuSbar                      ctermbg=192
hi PmenuSel         guifg=#F8F8F8 guibg=#9B703F
hi PmenuSel         ctermfg=255
hi PmenuThumb       guifg=#8F9D6A
hi PmenuThumb       ctermfg=65
hi Question         guifg=Green
hi Question         ctermfg=Green
hi Search           guibg=#5A647E
hi Search           ctermbg=57
hi StatusLine 	    guifg=#FFC66D guibg=#202020 gui=bold
hi StatusLine       ctermfg=215   ctermbg=234   cterm=bold
hi StatusLineNC     guifg=#888888 guibg=#202020 gui=none
hi StatusLineNC     ctermfg=241   ctermbg=234   cterm=none
hi VertSplit        guifg=#202020 guibg=#202020 gui=none
hi VertSplit        ctermfg=234   ctermbg=234
hi Visual                         guibg=#5A647E
hi Visual                         ctermbg=61
hi WarningMsg       guifg=#FE0000
hi WarningMsg       ctermfg=196


" Text/code elements
" ------------------

" any comment
hi Comment          guifg=#888888
hi Comment          ctermfg=246

" any constant
hi Constant         guifg=#6D9CBE
hi Constant         ctermfg=68
" a string constant: \"this is a string\"
hi String           guifg=#A5C261
hi String           ctermfg=149
" a character constant: 'c', '\n'
hi Character        guifg=#6D9CBE
hi Character        ctermfg=68
" a number constant: 234, 0xff
hi Number           guifg=#A5C261
hi Number           ctermfg=149
" a boolean constant: TRUE, false
hi Boolean          guifg=#6D9CBE
hi Boolean          ctermfg=68
" a floating point constant: 2.3e10
hi Float            guifg=#A5C261
hi Float            ctermfg=149

" any variable name
hi Identifier       guifg=#D0D0FF               gui=none
hi Identifier       ctermfg=189
" function name (also: methods for classes)
hi Function         guifg=#FFC66D               gui=none
hi Function         ctermfg=215

" any statement
hi Statement        guifg=#CC7833               gui=none
hi Statement        ctermfg=3
" if, then, else, endif, switch, etc.
hi Conditional      guifg=#CC7833
hi Conditional      ctermfg=3
" for, do, while, etc.
hi Repeat           guifg=#CC7833
hi Repeat           ctermfg=3
" case, default, etc.
hi Label            guifg=#CC7833
hi Label            ctermfg=3
" \"sizeof\", \"+\", \"*\", etc.
hi Operator         guifg=#CC7833
hi Operator         ctermfg=3
" any other keyword
hi Keyword          guifg=#CC7833
hi Keyword          ctermfg=3
" try, catch, throw
hi Exception        guifg=#CC7833
hi Exception        ctermfg=3

" generic Preprocessor
hi PreProc          guifg=#CC7833               gui=none
hi PreProc          ctermfg=3
" preprocessor #include
hi Include          guifg=#CC7833               gui=none
hi Include          ctermfg=3
" preprocessor #define
hi Define           guifg=#CC7833
hi Define           ctermfg=3
" same as Define
hi Macro            guifg=#CC7833               gui=none
hi Macro            ctermfg=3
" preprocessor #if, #else, #endif, etc.
hi PreCondit        guifg=#CC7833               gui=none
hi PreCondit        ctermfg=3

" int, long, char, etc.
hi Type             guifg=#DA4939               gui=none
hi Type             ctermfg=196
" static, register, volatile, etc.
hi StorageClass     guifg=#DA4939               gui=none
hi StorageClass     ctermfg=196
" struct, union, enum, etc.
hi Structure        guifg=#DA4939               gui=none
hi Structure        ctermfg=196
" A typedef
hi Typedef          guifg=#DA4939               gui=none
hi Typedef          ctermfg=196

" any special symbol
hi Special          guifg=Orange
hi Special          ctermfg=208
" special character in a constant
hi SpecialChar      guifg=Orange
hi SpecialChar      ctermfg=208
" character that needs attention
hi Delimiter        guifg=#519F50
hi Delimiter        ctermfg=71
" special things inside a comment
hi SpecialComment   guifg=Orange
hi SpecialComment   ctermfg=208
" debugging statements
hi Debug            guifg=Orange
hi Debug            ctermfg=208

" text that stands out, HTML links
hi Underlined       guifg=fg                    gui=underline
hi Underlined                                   cterm=underline

" left blank, hidden
hi Ignore           guifg=bg

" any erroneous construct
hi Error            guifg=#FFFFFF guibg=#990000
hi Error            ctermfg=15    ctermbg=1

" anything that needs extra attention; mostly the keywords TODO FIXME and XXX
hi Todo             guifg=#BC9458 guibg=NONE
hi Todo             ctermfg=137   ctermbg=NONE

" XML/HTML tags
hi xmlTag           guifg=#E8BF6A
hi xmlTag           ctermfg=216
hi xmlTagName       guifg=#E8BF6A
hi xmlTagName       ctermfg=216
hi xmlEndTag        guifg=#E8BF6A
hi xmlEndTag        ctermfg=216
hi link htmlTag              xmlTag
hi link htmlTagName          xmlTagName
hi link htmlEndTag           xmlEndTag

" other
hi MatchParen       guifg=Black   guibg=#FFCC20 gui=bold
hi MatchParen       ctermfg=0     ctermbg=220   cterm=bold
hi Title            guifg=#FFFFFF
hi Title            ctermfg=15
