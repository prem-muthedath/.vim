" source: https://gist.github.com/dave-kennedy/2188b3dd839ac4f73fe298799bb15f3b
" -- orig source: https://stackoverflow.com/a/24046914/2571881
" -- dave-kennedy's code a refinement of so code. for an exact copy of dave 
"    kennedy's code, see  ~/dotfiles/vim/ext/togglecomment.vim
" Prem:
"   -- edited key mappings
"   -- completely re-designed to do block comment/uncomment that mimics the 
"      manual comment/uncomment operation using Ctrl-v

let s:comment_map = {
      \   "c": '\/\/',
      \   "cpp": '\/\/',
      \   "go": '\/\/',
      \   "java": '\/\/',
      \   "javascript": '\/\/',
      \   "lua": '--',
      \   "scala": '\/\/',
      \   "php": '\/\/',
      \   "python": '#',
      \   "ruby": '#',
      \   "rust": '\/\/',
      \   "haskell": '--',
      \   "sh": '#',
      \   "profile": '#',
      \   "git": '#',
      \   "vim": '"',
      \   "desktop": '#',
      \   "fstab": '#',
      \   "conf": '#',
      \   "mail": '>',
      \   "eml": '>',
      \   "bat": 'REM',
      \   "ahk": ';',
      \   "tex": '%'
      \ }

function! s:commentleader() abort
  if has_key(s:comment_map, &filetype)
    return s:comment_map[&filetype]
  endif
  throw "no comment leader found for " . &filetype
endfunction

function! s:scanline(block_data) abort
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
  if getline('.') =~ '^\s*$'        " skip empty line
    return
  elseif getline('.') =~ '^\s*' . s:commentleader() . ' '
    let l:line_action = "uncomment-1"
  elseif getline('.') =~ '^\s*' . s:commentleader() . '\($\|\S\)'
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

function! s:uncomment()
  " Uncomment the line but do not delete any spaces
  execute 'normal ^' . len(s:commentleader()) . 'x'
endfunction

function! s:uncomment1()
  " Uncomment the line + remove 1 space, if any, that immediately follows
  call s:uncomment()
  execute 's/\%' . virtcol('.') . 'v\s//'
endfunction

function! s:comment(pos)
  " Comment the line + insert 1 space immediately after the comment symbol
  execute 'normal ' . a:pos . '|i' . s:commentleader() . " \<Esc>"
endfunction

function! s:updateline(block_data) abort
  " Execute 'block action' -- comment/uncomment -- on current line
  if getline('.')  =~ '^\s*$'       " skip empty line
    echom "note: blank line(s) not commented"
  elseif a:block_data["action"] == "uncomment-1"
    execute '.g/\v^\s*' . s:commentleader() . '/call s:uncomment1()'
  elseif a:block_data["action"] == "uncomment"
    execute '.g/\v^\s*' . s:commentleader() . '/call s:uncomment()'
  elseif a:block_data["action"] == "comment"
    call s:comment(a:block_data["insert_col"])
  else
    throw "s:updateline() -> no valid block action found"
  endif
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
  execute a:firstline . ',' . a:lastline . 'call s:scanline(l:block_data)'
  execute a:firstline . ',' . a:lastline . 'call s:updateline(l:block_data)'
endfunction


