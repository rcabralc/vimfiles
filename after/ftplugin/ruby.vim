" Functions for use with Ruby code.

" Promote to let
" ==============

" Transform 'foo = bar' into 'let(:foo) { bar }'
" Borrowed from @garybernhardt: https://github.com/garybernhardt
" Borrowed from @riccieri: https://github.com/riccieri

function! s:PromoteToLet()
  .s/\(\w\+\) = \(.*\)$/let(:\1) { \2 }/
  normal ==
  normal! f{w
endfunction


" Promote to do
" =============

" Borrowed from @riccieri: https://github.com/riccieri

function! s:PromoteToBlock()
" Go to closest '{'
  call search("{", 'ce', line('.'))
  call search("{", 'bce', line('.'))

  normal! "ddi{
  s/{\(\n\s*\)*}/do\rend/
  normal! k
  put d
  normal! k=2j
endfunction


" Mappings
" ========

" Ruby-Debugger

map <Leader>D :Rdebugger<Space>
map <Leader>P :RdbCommand<Space>p<Space>
map <Leader>L :RdbLog<CR>
map <Leader>S :RdbStop<CR>

" Rails

map <Leader><C-m> :Rmodel<Space>
map <Leader><C-v> :Rview<Space>
map <Leader><C-o> :Rcontroller<Space>
map <Leader><C-h> :Rhelper<Space>
map <Leader><C-s> :Rspec<Space>
map <Leader><C-l> :Rlib<Space>

nnoremap <Leader>l :call <SID>PromoteToLet()<CR>
nnoremap <Leader>B :call <SID>PromoteToBlock()<CR>
