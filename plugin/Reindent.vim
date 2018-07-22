" Reindent a block of lines
"   -- preserves trailing spaces
"   -- works with vim, bash, but not haskell; untested for others
"   -- author: Prem Muthedath

"   usage:
"   -- select >= 2 lines, and call Reindent(), and all selected lines (except 
"      1st) will be reindented with respect to the 1st line in selection.
"   -- reindent works only if you select > 1 line.
function! s:reindentline() abort
  " Reindent the next line"
  execute "normal J"
  execute "normal i"
endfunction

function! Reindent() range abort
  " Reindent a range of lines"
  if a:firstline == line('$')
    echom "just the last line selected; reindent needs > 1 line selected"
  elseif a:firstline == a:lastline
    echom "reindent works only if you select > 1 line"
  else
    try
      set formatoptions-=r
      set formatoptions-=j
      execute
            \ a:firstline .
            \ ',' .
            \ (a:lastline-1) .
            \ 'call s:reindentline()'
    catch /.*/
      echom "Reindent() -> caught error: " . v:exception
    finally
      set formatoptions+=r
      set formatoptions+=j
    endtry
  endif
endfunction


