" source: https://gist.github.com/dave-kennedy/2188b3dd839ac4f73fe298799bb15f3b
" -- orig source: https://stackoverflow.com/a/24046914/2571881
" -- dave-kennedy's code a refinement of so code. for an exact copy of dave 
"    kennedy's code, see  ~/dotfiles/vim/ext/togglecomment.vim
" Prem:
"   -- edited key mappings
"   -- completely re-designed to do block comment/uncomment that mimics the 
"      manual comment/uncomment operation using Ctrl-v

function! s:emptyendpat() abort
  if len(Cs()) > 1
    return '^\s*$' . '\|^\s*' . s:esc(Cs()[2])
  endif
  return '$a'
endfunction

function! s:uncomment1(first) abort
  " Uncomment the line + remove 1 space, if any, that immediately follows
  call s:uncomment(a:first)
  silent! execute 's/\%' . virtcol('.') . 'v\s//'
endfunction

function! s:uncomment(first) abort
  " Uncomment the line but do not delete any spaces
  execute 'normal 0/' . "\\%" . line('.') . 'l^\s*' . s:esc(a:first) .
        \ '/e-' . (strdisplaywidth(a:first)-1) . "\<CR>"
  execute 'normal ' . (strdisplaywidth(a:first)) . '"_x'
endfunction

function! s:uncommentend(second) abort
  " Uncomment the line end, if needed
  if len(a:second)
    execute 'normal 0/' . "\\%" . line('.') . 'l' .
          \ s:esc(a:second) . '\s*$' . "\<CR>"
    execute 'normal ' . (strdisplaywidth(a:second)) . '"_x'
    silent! execute 's/\%' . virtcol('.') . 'v\s//'
  endif
endfunction

function! s:comment(col, first) abort
  " Comment the line + insert 1 space immediately after the comment symbol
  execute 'normal ' . a:col . '|i' . a:first . " \<Esc>"
endfunction

function! s:commentend(second) abort
  if len(a:second)
    execute 'normal A' . ' ' . a:second . "\<Esc>"
  endif
endfunction

function! s:updateline(block_data, first, second) abort
  " Execute 'block action' -- comment/uncomment -- on current line
  if a:block_data["action"] == "uncomment-1"
    call s:uncomment1(a:first)
    call s:uncommentend(a:second)
  elseif a:block_data["action"] == "uncomment"
    call s:uncomment(a:first)
    call s:uncommentend(a:second)
  elseif a:block_data["action"] == "comment"
    call s:comment(a:block_data["insert_col"], a:first)
    call s:commentend(a:second)
  else
    throw "s:updateline() -> no valid block action found"
  endif
endfunction

function! s:updatestr(first, second) abort
  return 'call s:updateline(l:block_data' .
        \ ',' .
        \ a:first .
        \ ', ' .
        \ a:second .
        \ ')'
endfunction

function! s:blockupdate(flag) abort
  if len(Cs()) == 1 || a:flag == 'f'
    return s:updatestr('Cs()[0]', '""')
  elseif a:flag == 'm'
    return s:updatestr('" " . Cs()[1]', '""')
  elseif a:flag == 'ee'
    return s:updatestr('" " . Cs()[2]', '""')
  elseif a:flag == 'e'
    return s:updatestr('" " . Cs()[1]', 'Cs()[2]')
  else
    throw "s:blockupdate() -> no valid flag found"
  endif
endfunction

function! s:lineupdate() abort
  if len(Cs()) == 1
    return s:updatestr('Cs()[0]', '""')
  endif
  return s:updatestr('Cs()[0]', 'Cs()[2]')
endfunction

function! s:scanline(block_data, commentpat) abort
  " Scan current line and, if relevant, update block data with line info
  " line info has 2 pieces:
  "   -- comment column (i.e., first non-blank virtual column)
  "   -- action, which describes what should be done to the line on toggle:
  "         1. uncomment-1: uncomment + remove 1 space that follows immediately
  "         2. uncomment: just uncomment; do not remove any spaces
  "         3. comment: comment the line
  " we update block data if either/both of these conditions occur:
  "   -- if line's comment column < insert_column in block data
  "   -- if line's action is "comment", but block data's action is not
  normal! ^
  if getline('.') =~ '^\s*$'
    let a:block_data["action"] = "comment"
  elseif getline('.') =~ '^\s*' . a:commentpat . ' '
    let l:line_action = "uncomment-1"
  elseif getline('.') =~ '^\s*' . a:commentpat . '\($\|\S\)'
    let l:line_action = "uncomment"
  elseif a:block_data["action"] != "comment"
    let a:block_data["action"] = "comment"
  endif
  if virtcol('.') < a:block_data["insert_col"]
    let a:block_data["insert_col"] = virtcol('.')
    if a:block_data["action"] != "comment"
      let a:block_data["action"] = l:line_action
    endif
  endif
endfunction

function! s:esc(str) abort
  return escape(a:str, "\/*|")
endfunction

function! s:middle() abort
  let l:mb = filter(split(&comments, ','), 'v:val=~"mb:"')
  if len(l:mb) == 1
    return split(l:mb[0], ':')[1]
  endif
  throw "s:middle() -> no 'mb:' found for a 3-part comment in &comments"
endfunction

function! Cs() abort
   let l:comment = split(&commentstring, '%s')
   if len(l:comment) == 2
     let l:comment = [l:comment[0], s:middle(), l:comment[1]]
   endif
   return l:comment
 endfunction

function! s:commentpat(linewise) abort
  if a:linewise
    return s:esc(Cs()[0])
  endif
  return '\(' . s:esc(join(Cs(), '|')) . '\)'
endfunction

function! s:scanstr(linewise) abort
  return 'call s:scanline(l:block_data, s:commentpat(' . a:linewise . '))'
endfunction

function! ToggleComments() range abort
  " Uniformly toggle comments for a block (i.e., a range of lines)
  " Rules:
  "   1. comment/uncomment operations should never change the relative 
  "      indentation within the selected block.
  "   2. uniform block toggle -- i.e., on toggle, we either comment all lines or 
  "      uncomment all lines.  `l:block_data["action"]` models this in code.
  "   3. we uncomment all lines only if all lines are comments; else, we always 
  "      comment all lines, even if some lines are comments.
  "   4. when we uncomment, we only remove the leading comment symbol.  so if 
  "      some lines that were already comments had been commented again (see 
  "      rule 3), when we uncomment, those lines will still be comments, 
  "      although now they will only have 1 leading comment symbol.
  "   5. when we comment, we insert the comment symbol at the same column for 
  "      all lines.  this column is the least non-blank virtual column in the 
  "      entire block.  `l:block_data["insert_col"]` models this in code.
  "   6. when we uncomment, we will choose one of the options below and apply 
  "      that same option to every line in the block:
  "         a) just uncomment and do nothing else; or,
  "         b) uncomment & remove 1 space, if any, that immediately follows.
  "      how do we decide?
  "         -- find the first line in selection with the least comment column
  "         -- is that line's comment symbol followed by 0 spaces?
  "         -- yes? => apply option (a) to every line in the block
  "         -- no?  => apply option (b) to every line in the block
  "      `l:block_data["action"]` models this in code.
  " These rules match with those used in manual comment/uncomment using Ctrl-v
  let l:block_data = { "action" : "", "insert_col" : 1000 }
  if a:firstline == a:lastline
    execute a:firstline . s:scanstr(1)
    execute a:firstline . s:lineupdate()
  else
    execute a:firstline . ',' . a:lastline . s:scanstr(0)
    execute a:firstline . s:blockupdate('f')
    if a:lastline > a:firstline + 1
      execute (a:firstline+1) . ',' . (a:lastline-1) . s:blockupdate('m')
    endif
    if getline(a:lastline) =~ s:emptyendpat()
      execute a:lastline . s:blockupdate('ee')
    else
      execute a:lastline . s:blockupdate('e')
    endif
  endif
endfunction



