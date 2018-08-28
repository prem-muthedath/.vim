" This has just a collection of utility functions written as and when needed.

function! Csformat()
  " Format file -- such as ~/dotfiles/vim/notes/cs.vim -- containing list of 
  " filenames and &comments into neatly seperated columns;
  " sample output: ~/dotfiles/vim/notes/cs-col.vim
  let m=0
  g/vim:/
        \ execute 'normal ' . "/^.*vim:/e" . "\<CR>" 
        \ | let m = max([m, virtcol('.')]) 
  g/vim:/
        \ execute 's/\(^\S\+\.vim:\)[^=]*\(comment\|com\)/\1\2'
        \ | execute 'normal 0' . "/^.*vim:/e" . "\<CR>" 
        \ | let diff = m - virtcol('.') + 3
        \ | execute 'normal a' . repeat(" ", diff)
endfunction



