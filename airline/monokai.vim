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
            \ 'red':    [s:magenta, '', s:tmagenta, '', ''],
            \ 'green':  [s:lime, '', s:tlime, '', ''],
            \ 'blue':   [s:cyan, '', s:tcyan, '', ''],
            \ 'yellow': [s:yellow, '', s:tyellow, '', ''],
            \ 'orange': [s:orange, '', s:torange, '', ''],
            \ 'purple': [s:purple, '', s:tpurple, '', ''],
            \ }


let s:inactive_palette = [s:lightgray, s:darkgray, s:tlightgray, s:tdarkgray]

let s:mode_palette = [s:white, s:black, s:twhite, s:tblack, '']
let s:info_palette = [s:white, s:darkgray, s:twhite, s:tdarkgray, '']
let s:status_palette = [s:lime, s:black, s:tlime, s:tblack, 'bold']
let s:status_modified = [s:magenta, s:black, s:tmagenta , s:tblack, 'bold']

let s:default_palette = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let s:modified_palette = {
            \ 'airline_c': s:status_modified,
            \ }

" Normal mode
let g:airline#themes#monokai#palette.normal = s:default_palette
let g:airline#themes#monokai#palette.normal_modified = s:modified_palette


" Insert mode
let g:airline#themes#monokai#palette.insert = copy(s:default_palette)
let g:airline#themes#monokai#palette.insert.airline_a = [s:black, s:cyan, s:tblack, s:tcyan, '']
let g:airline#themes#monokai#palette.insert_modified = s:modified_palette


" Replace mode
let g:airline#themes#monokai#palette.replace = copy(s:default_palette)
let g:airline#themes#monokai#palette.replace.airline_a = [s:black, s:magenta, s:tblack, s:tmagenta, '']
let g:airline#themes#monokai#palette.replace_modified = s:modified_palette


" Visual mode
let g:airline#themes#monokai#palette.visual = copy(s:default_palette)
let g:airline#themes#monokai#palette.visual.airline_a = [s:black, s:orange, s:tblack, s:torange, '']
let g:airline#themes#monokai#palette.visual_modified = s:modified_palette


" Inactive
let s:IA = [s:lightgray, s:darkgray, s:tlightgray, s:tdarkgray]
let g:airline#themes#monokai#palette.inactive = airline#themes#generate_color_map(s:IA, s:IA, s:IA)
let g:airline#themes#monokai#palette.inactive_modified = s:modified_palette


" CtrlP
if !get(g:, 'loaded_ctrlp', 0)
  finish
endif
let g:airline#themes#monokai#palette.ctrlp = airline#extensions#ctrlp#generate_color_map(
            \ [s:white, s:lightgray, s:twhite, s:tlightgray, 'bold'],
            \ [s:white, s:black,     s:twhite, s:tblack,     'bold'],
            \ [s:black, s:yellow,    s:tblack, s:tyellow,    ''])


let g:airline_theme = 'monokai'
