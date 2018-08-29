" Build a list of comment symbols for current buffer
"   -- comment symbols extracted from &commentstring and &comments
"   -- allowed list sizes: 1 (1-part comment) or 3 (3-part comment)
"   -- for list size 1, you just have a comment symbol @ start of line, used 
"      both for single lines as well as for a block of lines
"   -- for list size 3, you've 3 comment symbols:
"       -- start symbol @ start of first line of comment block
"       -- middle symbol @ start of lines > first and <= last
"       -- end symbol @ end of last line
"   -- unless comment symbol entirely whitespace, trailing spaces removed
" NOTE:
" for 3-part comment, line comment, unlike block, will just use 'start' & 'end' 
" symbols, since single line has no "middle" line, & 1st line = last line
function! Cs() abort
  let l:comment = split(&commentstring, '%s')
  if len(l:comment) == 2
    let l:comment = [l:comment[0], s:middle(), l:comment[1]]
  endif
  return map(l:comment, {key, val -> matchstr(val, '^\S\+\|^\s\+$')})
endfunction

function! s:middle() abort
  " Get middle part comment symbol from &comments for current buffer
  let l:mb = filter(split(&comments, ','), {key, val -> val =~ 'mb:\|m:'})
  if len(l:mb) >= 1
    return split(l:mb[0], ':')[1]
  endif
  throw "s:middle() -> no 'mb:\|m:' found for a 3-part comment in &comments"
endfunction


