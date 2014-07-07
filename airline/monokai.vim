" Palette
let s:black     = "#272822"
let s:darkgray  = "#49483e"
let s:lightgray = "#75715e"
let s:white     = "#f8f8f2"
let s:lime      = "#a6e22e"
let s:yellow    = "#e6db74"
let s:purple    = "#ae81ff"
let s:cyan      = "#66d9ef"
let s:orange    = "#fd971f"
let s:magenta   = "#f92672"

" Terminal versions
let s:tblack     = 235
let s:tdarkgray  = 238
let s:tlightgray = 242
let s:twhite     = 255
let s:tlime      = 148
let s:tyellow    = 186
let s:tpurple    = 141
let s:tcyan      = 81
let s:torange    = 208
let s:tmagenta   = 197


let g:airline#themes#monokai#palette = {}

let g:airline#themes#monokai#palette.accents = {
            \ 'red':    [s:magenta, '', s:tmagenta , '', ''],
            \ 'green':  [s:lime,    '', s:tlime,     '', ''],
            \ 'blue':   [s:cyan,    '', s:tcyan,     '', ''],
            \ 'yellow': [s:yellow,  '', s:tyellow,   '', ''],
            \ 'orange': [s:orange,  '', s:torange,   '', ''],
            \ 'purple': [s:purple,  '', s:tpurple,   '', ''],
            \ }


" Normal mode
let s:N1 = [s:black, s:lightgray, s:tblack, s:tlightgray] " mode
let s:N2 = [s:white, s:darkgray, s:twhite, s:tdarkgray] " info
let s:N3 = [s:lightgray, s:black, s:tlightgray, s:tblack] " statusline

let g:airline#themes#monokai#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#monokai#palette.normal_modified = {
            \ 'airline_c': [s:white, s:black, s:twhite , s:tblack, ''],
            \ }


" Insert mode
let g:airline#themes#monokai#palette.insert = copy(g:airline#themes#monokai#palette.normal)
let g:airline#themes#monokai#palette.insert.airline_a = [s:N1[0], s:cyan, s:N1[2], s:tcyan, '']
let g:airline#themes#monokai#palette.insert_modified = {
            \ 'airline_c': [s:white, s:black, s:twhite, s:tblack, ''],
            \ }


" Replace mode
let g:airline#themes#monokai#palette.replace = copy(g:airline#themes#monokai#palette.normal)
let g:airline#themes#monokai#palette.replace.airline_a = [s:N1[0], s:magenta, s:N1[2], s:tmagenta, '']
let g:airline#themes#monokai#palette.replace_modified = {
            \ 'airline_c': [s:white, s:black, s:twhite, s:tblack, ''],
            \ }


" Visual mode
let g:airline#themes#monokai#palette.visual = copy(g:airline#themes#monokai#palette.normal)
let g:airline#themes#monokai#palette.visual.airline_a = [s:N1[0], s:orange, s:N1[2], s:torange, '']
let g:airline#themes#monokai#palette.visual_modified = {
            \ 'airline_c': [s:white, s:black, s:twhite, s:tblack, ''],
            \ }


" Inactive
let s:IA = [s:lightgray, s:darkgray, s:tlightgray, s:tdarkgray]
let g:airline#themes#monokai#palette.inactive = airline#themes#generate_color_map(s:IA, s:IA, s:IA)
let g:airline#themes#monokai#palette.inactive_modified = {
            \ 'airline_c': [s:white, '', s:twhite, '', ''],
            \ }


" CtrlP
if !get(g:, 'loaded_ctrlp', 0)
  finish
endif
let g:airline#themes#monokai#palette.ctrlp = airline#extensions#ctrlp#generate_color_map(
            \ [s:white, s:lightgray, s:twhite, s:tlightgray, 'bold'],
            \ [s:white, s:black,     s:twhite, s:tblack,     'bold'],
            \ [s:black, s:yellow,    s:tblack, s:tyellow,    ''])


let g:airline_theme = 'monokai'
