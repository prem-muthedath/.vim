" source: https://gist.github.com/dave-kennedy/2188b3dd839ac4f73fe298799bb15f3b
" orig source: https://stackoverflow.com/a/24046914/2571881
" dave-kennedy's code a refinement of so code
" Prem:
"   -- fine-tuned comment-map
"   -- removed key mappings
"   -- rest ~ as dave-keenedy

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

function! ToggleComment()
    if has_key(s:comment_map, &filetype)
        let l:comment_leader = s:comment_map[&filetype]
        if getline('.') =~ '^\s*$'
            " Skip empty line
            return
        endif
        if getline('.') =~ '^\s*' . l:comment_leader
            " Uncomment the line
            execute 'silent s/\v\s*\zs' . l:comment_leader . '\s*\ze//'
        else
            " Comment the line
            execute 'silent s/\v^(\s*)/\1' . l:comment_leader . ' /'
        endif
    else
        echo "No comment leader found for filetype"
    endif
endfunction



