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
      \   "tex": '%',
      \ }

function! s:commentleader() abort
  if has_key(s:comment_map, &filetype)
    return s:comment_map[&filetype]
  endif
endfunction

function! s:scanline(block_data) abort
  " Scan current line and add its info to the block data
  " line info has 2 pieces:
  "   -- comment column (i.e., first non-blank virtual column)
  "   -- action, which describes what should be done to the line on toggle:
  "         1. uncomment-1: uncomment + remove 1 space that follows immediately
  "         2. uncomment: just uncomment; do not remove any spaces
  "         3. comment: comment the line
  execute "normal ^"
  if getline('.') =~ '^\s*' . s:commentleader() . ' '
    call add(a:block_data, [virtcol('.'), "uncomment-1"])
  elseif getline('.') =~ '^\s*' . s:commentleader() . '\S'
    call add(a:block_data, [virtcol('.'), "uncomment"])
  else
    call add(a:block_data, [virtcol('.'), "comment"])
  endif
endfunction

function! s:updateline(insert_col, block_action) abort
  " Execute 'block action' -- comment/uncomment -- on current line
  if getline('.')  =~ '^\s*$'
    " skip empty line
    return
  endif
  if a:block_action == "uncomment-1"
    " uncomment the line + remove 1 space that immediately follows
    execute
          \ 'silent s/\v^\s*\zs' .
          \ '(' .
          \ s:commentleader() .
          \ ' ' .
          \ '|' .
          \ s:commentleader() .
          \ ')' .
          \ '(\s*)\ze/\2/'
  elseif a:block_action == "uncomment"
    " uncomment the line but do not delete any spaces
    execute
          \ 'silent s/\v^\s*\zs' .
          \ s:commentleader() .
          \ '(\s*)\ze/\1/'
  else
    " comment the line + insert 1 space immediately after the comment symbol
    execute
          \ 'silent s/\v' .
          \ "\%" .
          \ a:insert_col .
          \ "v" .
          \ '/' .
          \ s:commentleader()  .
          \ ' /'
  endif
endfunction

function! ToggleComments() range abort
  " Uniformly toggle comments for a block (i.e., a range of lines)
  " Rules:
  "   1. comment/uncomment operations should never change the relative 
  "      indentation within the selected block.
  "   2. uniform block toggle -- i.e., on toggle, we either comment all lines or 
  "      uncomment all lines.  we capture this in code using `l:block_action`.
  "   3. we uncomment all lines only if all lines are comments; else, we always 
  "      comment all lines, even if some lines are comments.
  "   4. when we uncomment, we only remove the leading comment symbol.  so if 
  "      some lines that were already comments had been commented again (see 
  "      rule 3), when we uncomment, those lines will still be comments, 
  "      although now they will only have 1 leading comment symbol.
  "   5. when we comment, we insert the comment symbol at the same column for 
  "      all lines.  this column is the least non-blank virtual column in the 
  "      entire block.  we model this column in code using `l:block_col_min`.
  "   6. when we uncomment, we may:
  "         a) either just uncomment and do nothing else;
  "         b) or we may uncomment & remove 1 space that immediately follows.
  "      how do we decide?
  "         -- get the first line associated with `l:block_col_min`
  "         -- is that line's comment symbol followed by 0 spaces?
  "         -- yes? => option (a)
  "         -- no?  => option (b)
  "      `l:block_action` associated with `l:block_col_min` models this in code.
  " These rules match with those used in manual comment/uncomment using Ctrl-v
  let l:block_col_min = 1000
  let l:block_data = []
  let l:block_action = ""
  silent execute
        \ a:firstline.
        \ ','.
        \ a:lastline.
        \ 'call s:scanline(l:block_data)'
  for [line_start_col, line_action] in l:block_data
    if line_action == "comment"
      let l:block_action = line_action
    endif
    if line_start_col < l:block_col_min
      let l:block_col_min = line_start_col
      if l:block_action != "comment" | let l:block_action = line_action | endif
    endif
  endfor

  silent execute
        \ a:firstline.
        \ ','.
        \ a:lastline.
        \ 'call s:updateline(l:block_col_min, l:block_action)'
endfunction


