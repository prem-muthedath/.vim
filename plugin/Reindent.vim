" Reindent a block of lines
"   -- Preserves trailing spaces
"   -- Works with vim, but not haskell.  Haven't tried for other ft
"   -- author: Prem Muthedath

function! Reindent() abort
  set formatoptions-=r
  set formatoptions-=j
  execute "normal! J"
  execute "normal! i"
  set formatoptions+=r
  set formatoptions+=j
endfunction


