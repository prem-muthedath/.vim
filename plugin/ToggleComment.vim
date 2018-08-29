" source: https://gist.github.com/dave-kennedy/2188b3dd839ac4f73fe298799bb15f3b
" -- orig source: https://stackoverflow.com/a/24046914/2571881
" -- dave-kennedy's code a refinement of so code. for an exact copy of dave 
"    kennedy's code, see  ~/dotfiles/vim/ext/togglecomment.vim
" Prem:
"   --  entirely re-designed -> almost no resemblance to dave-kennedy's code
"   --  handles both 1-part & 3-part (c-style) comments
"   --  extracts comment symbols from &commestring and &comments
"   --  uses normal mode commands, almost entirely, for comment/uncomment

function! s:emptyllendpat() abort
  " Return regex pattern for end of an empty last line (ll) in comment block
  " for 3-part comment:
  "   -- '^\s*$' -> end of an empty uncommented ll
  "   -- s:esc(Cs()[2]) -> end of an empty commented ll
  " for 1-part comment:
  "   -- '$a' -> matches nothing, as we don't need to match 'end' of line
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
  execute 'normal 0/' . "\\%" . line('.') . 'l^\s*' . s:esc(a:first) . '/e-' .
        \ (strdisplaywidth(a:first)-1) . "\<CR>"
  execute 'normal ' . (strdisplaywidth(a:first)) . '"_x'
endfunction

function! s:uncommentend(second) abort
  " Uncomment line end, if needed, & remove 1 immediate preceeding \s, if any
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
  " Comment line end, if needed, & insert 1 space before the comment symbol
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
  " Return call-string for s:updateline()
  return 'call s:updateline(l:block_data' .
        \ ',' .
        \ a:first .
        \ ', ' .
        \ a:second .
        \ ')'
endfunction

function! s:blockupdate(flag) abort
  " Using s:updatestr(), generate call-string for block comment/uncomment
  "   -- for 1-part comment, Cs()=1, treat block as series of line comments
  "   -- for 3-part comment, if middle empty, again, treat block as series of 
  "      line comments; otherwise, generate call-string based on flag:
  "       1) f  ->  first line in comment block
  "       2) m  ->  middle part of block: firstline < line < lastline
  "       3) el ->  empty last line
  "       4) l  ->  last line
  " NOTE:
  " -- this function is just a call-string generator
  " -- execute calls this function only when it first evaluates expression to 
  "    generate the string, later used in line-by-line execution
  " -- expression evaluation occurs not for each line, but once per flag
  if len(Cs()) == 1 || Cs()[1] =~ '^\s*$'
    return s:lineupdate()
  elseif a:flag == 'f'
    return s:updatestr('Cs()[0]', '""')
  elseif a:flag == 'm'
    return s:updatestr('" " . Cs()[1]', '""')
  elseif a:flag == 'el'
    return s:updatestr('" " . Cs()[2]', '""')
  elseif a:flag == 'l'
    return s:updatestr('" " . Cs()[1]', 'Cs()[2]')
  else
    throw "s:blockupdate() -> no valid flag found"
  endif
endfunction

function! s:lineupdate() abort
  " Generate, using updatestr(), call-string for linewise comment/uncomment
  " call-string based on Cs(), i.e., 1-part or 3-part comment
  " NOTE: for 3-part comment, line comment will just use 'start' & 'end' 
  " symbols, since single line has no "middle" line, & 1st line = last line
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
  " NOTE: a:commentpat -> regex pattern to detect comment symbol(s)
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
  " Wrapper function that returns escaped value -- needed in regex patterns
  return escape(a:str, "\/*|")
endfunction

function! s:commentpat(linewise) abort
  " For current buffer, return comment symbol(s) as a regex pattern
  "   -- for 1-part comment, same regex for both linewise & block comment
  "   -- but for 3-part comment, regex based on linewise vs block
  "   -- regex pattern used in s:scanline() to detect a comment
  if a:linewise
    return s:esc(Cs()[0])
  endif
  return '\(' . s:esc(join(Cs(), '|')) . '\)'
endfunction

function! s:scanstr(linewise) abort
  " Return s:scanline() call-string for current buffer
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
  "   4. when we uncomment, we only remove the leading comment symbol. and if 
  "      applicable, the trailing comment symbol.  so if some lines that were 
  "      already comments had been commented again (see rule 3), when we 
  "      uncomment, those lines will still be comments, although now they will 
  "      only have 1 leading comment symbol.
  "   5. when we comment, we insert the leading comment symbol at the same 
  "      column for all lines.  this column is the least non-blank virtual 
  "      column in the block; `l:block_data["insert_col"]` models it in code.
  "   6. when we uncomment, we will choose one of the options below for the 
  "      leading comment, and apply that same option to every line in the block:
  "         a) just uncomment and do nothing else; or,
  "         b) uncomment & remove 1 space, if any, that immediately follows.
  "      how do we decide?
  "         -- find the first line in selection with the least comment column
  "         -- is that line's leading comment symbol followed by 0 spaces?
  "         -- yes? => apply option (a) to every line in the block
  "         -- no?  => apply option (b) to every line in the block
  "      `l:block_data["action"]` models this in code.
  "   7. trailing comment/uncomment:
  "       -- done only when &commentstring ~ 'leading-symbol%strailing-symbol'
  "       -- comment: add 1 \s followed by trailing comment symbol @ END
  "       -- uncomment: chop 1 \s, if any, + trailing comment symbol @ END
  "       -- for linewise, END = 'EOL'; for block, END = EOL of last line
  " Rules 1-6 match those used in manual comment/uncomment using Ctrl-v
  " Method:
  " we distinguish 2 main categories:
  "   -- 1-part comment vs 3-part comment
  "   -- linewise comment vs block comment
  " 1-part:
  "   -- &commentstring ~ 'leadingsymbol%s'
  "   -- linewise ~ block -> both have just a leading comment symbol
  " 3-part:
  "   -- &commentstring ~ 'leadingsymbol%strailingsymbol'
  "   -- middle symbol comes from 'mb' part of &comments
  "   -- linewise -> leading symbol ... trailing symbol (example, /* ... */)
  "   -- block    -> has middle symbol as well (example, /* * */); to do this, 
  "      block split into 3, based on line position:
  "       - firstline (f): leading symbol ...
  "       - middle (m) -> for firstline < line < lastline: middle symbol ...
  "       - empty lastline (el): ... trailing symbol OR
  "       - non-empty lastline (l): middle symbol ... trailing symbol
  try
    set formatoptions-=a          " turn off autoindent
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
      if getline(a:lastline) =~ s:emptyllendpat()
        execute a:lastline . s:blockupdate('el')
      else
        execute a:lastline . s:blockupdate('l')
      endif
    endif
  finally
    set formatoptions+=a
  endtry
endfunction



