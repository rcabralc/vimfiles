" Functions for use with Ruby code.

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

nnoremap <Leader>B :call <SID>PromoteToBlock()<CR>
