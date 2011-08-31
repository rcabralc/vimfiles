" Vim color scheme
"
" Name:        railscast.vim
" Maintainer:  Josh O'Rourke <jorourke23@gmail.com> 
" License:     public domain
"
" A GUI Only port of the RailsCasts TextMate theme [1] to Vim.
" Some parts of this theme were borrowed from the well-documented Lucius theme [2].
" 
" [1] http://railscasts.com/about 
" [2] http://www.vim.org/scripts/script.php?script_id=2536

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "rcabralc2"

" Colors
" Brown        #BC9458
" Dark Blue    #6D9CBE
" Dark Green   #519F50
" Dark Orange  #CC7833
" Light Blue   #D0D0FF
" Light Green  #A5C261
" Tan          #FFC66D

" Window elements
" ---------------

hi Cursor                    guibg=#FFFFFF
hi CursorLine                guibg=#333435
hi LineNr                    guifg=#888888 guibg=#333333
hi Normal                    guifg=#E6E1DC guibg=#181818
hi Search                    guibg=#5A647E
hi StatusLine 	             guifg=#FFFFFF guibg=#101010 gui=bold
hi StatusLineNC              guifg=#888888 guibg=#101010 gui=NONE
hi VertSplit                 guifg=#202020 guibg=#101010 gui=NONE
hi Visual                    guibg=#5A647E
hi ColorColumn                             guibg=#101010

" Folds
" -----
" line used for closed folds
hi Folded                    guifg=#F6F3E8 guibg=#444444 gui=NONE

" Misc
" ----
" directory names and other special names in listings
hi Directory                 guifg=#A5C261 gui=NONE
hi MatchParen                guifg=#FFFFFF guibg=DarkCyan
hi Question                  guifg=Green
hi Title                     guifg=#FFFFFF
hi WarningMsg                guifg=#FE0000


" Popup Menu
" ----------
" normal item in popup
hi Pmenu                     guifg=#F6F3E8 guibg=#444444 gui=NONE
" selected item in popup
hi PmenuSel                  guifg=#000000 guibg=#A5C261 gui=NONE
" scrollbar in popup
hi PMenuSbar                 guibg=#5A647E gui=NONE
" thumb of the scrollbar in the popup
hi PMenuThumb                guibg=#AAAAAA gui=NONE


" a boolean constant: TRUE, false
hi Boolean                   guifg=#6D9CBE

" a character constant: 'c', '\n'
hi Character                 guifg=#6D9CBE

"rubyComment
hi Comment                   guifg=#888888 gui=italic
hi Todo                      guifg=#BC9458 guibg=NONE gui=italic

"rubyPseudoVariable
"nil, self, symbols, etc
hi Constant                  guifg=#6D9CBE

" if, then, else, endif, switch, etc.
hi Conditional               guifg=#CC7833

" debugging statements
hi Debug                     guifg=Orange

"rubyClass, rubyModule, rubyDefine
"def, end, include, etc
hi Define                    guifg=#CC7833

"rubyInterpolation
hi Delimiter                 guifg=#519F50

"rubyError, rubyInvalidVariable
hi Error                     guifg=#FFFFFF guibg=#990000

" try, catch, throw
hi Exception                 guifg=#CC7833

" a floating point constant: 2.3e10
hi Float                     guifg=#A5C261

"rubyFunction
hi Function                  guifg=#FFC66D gui=NONE

"rubyIdentifier
"@var, @@var, $var, etc
hi Identifier                guifg=#D0D0FF gui=NONE

" left blank, hidden
hi Ignore                    guifg=bg

"rubyInclude
"include, autoload, extend, load, require
hi Include                   guifg=#CC7833 gui=NONE

"rubyKeyword, rubyKeywordAsMethod
"alias, undef, super, yield, callcc, caller, lambda, proc
hi Keyword                   guifg=#CC7833

" case, default, etc.
hi Label                     guifg=#CC7833

" same as define
hi Macro                     guifg=#CC7833 gui=NONE

"rubyInteger
hi Number                    guifg=#A5C261

" \"sizeof\", \"+\", \"*\", etc.
hi Operator                  guifg=#CC7833

" #if, #else, #endif
hi PreCondit                 guifg=#CC7833 gui=NONE

" generic preprocessor
hi PreProc                   guifg=#CC7833 gui=NONE

" for, do, while, etc.
hi Repeat                    guifg=#CC7833

"rubyControl, rubyAccess, rubyEval
"case, begin, do, for, if unless, while, until else, etc.
hi Statement                 guifg=#CC7833 gui=NONE

" static, register, volatile, etc.
hi StorageClass              guifg=#DA4939 gui=NONE

" any special symbol
hi Special                   guifg=Orange

" special character in a constant
hi SpecialChar               guifg=Orange

" special things inside a comment
hi SpecialComment            guifg=Orange

"rubyString
hi String                    guifg=#A5C261

" anything that needs extra attention; mostly the keywords TODO FIXME and XXX
hi Todo                      guifg=#BC9458 guibg=NONE gui=italic

" text that stands out, HTML links
hi Underlined                guifg=fg                 gui=underline

"rubyConstant
hi Type                      guifg=#DA4939 gui=NONE

hi DiffAdd                   guifg=#E6E1DC guibg=#144212
hi DiffDelete                guifg=#E6E1DC guibg=#660000

hi link htmlTag              xmlTag
hi link htmlTagName          xmlTagName
hi link htmlEndTag           xmlEndTag

hi xmlTag                    guifg=#E8BF6A
hi xmlTagName                guifg=#E8BF6A
hi xmlEndTag                 guifg=#E8BF6A
