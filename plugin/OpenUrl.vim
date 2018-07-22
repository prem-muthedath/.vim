" #######################################################
" this function opens the url under the cursor in safari
" #######################################################
" to view an url:
"       -- in vimrc, create a key binding (suggested), such as:
"             nmap <Leader>o :call OpenUrlUnderCursor()<CR>
"       -- place your cursor anywhere on the url
"       -- and then press \o
"    \ is the default mapleader --> default value of <Leader>
"    see /u/ xuan, /u/ tivn @ https://goo.gl/4jrkh6 (so)
"
" code source: /u/ mauro morales @ https://goo.gl/m9PsWW (so)
" i made a few changes to the code:
"    1. fixed a bug -- morales code doesn't handle # and ? in urls;
"       fixed it using fnameescape() -- see code below.
"       for info on fnameescape, see /u/ evergreentree, /u/ sato
"       katsura @ https://goo.gl/cS8eKk (vi.stackexchange)
"
"       escape(), instead of fnameescape(), works as well.
"       in our case, escape(url-string, "?%!#") works just fine.
"       ref: see /u/ konstantin, /u/ tim @ https://goo.gl/hJHFDs
"       (vim.1045645.n5.nabble.com)
"
"    2. in exec command argument string, added space before &
"       after . (string concatenation operator), for easier read
"    3. removed redundant quotes in the exec command argument string:
"       changed " '" . url . "'" to " " . url, as url is already
"       a string, so it doesn't need to be quoted again
"
" few comments on the code:
"    1. exec -- a vim command -- takes a string argument, sometimes
"       written using the . operator, a string concatenater.
"       exec uses . operator to create one single string argument.
"       for example, if your url is "google.com", you'll get:
"           exec "open -a " . "/Applications/Safari.app " . "google.com"
"       which will become:
"           exec "open -a /Applications/Safari.app google.com"
"    2. open -a -> open is an OS X command; -a option opens an application
"    3. silent prevents the external command run by exec from
"       triggering the "Hit Enter" prompt to redraw vim screen
"       see https://goo.gl/z21rDQ (vim.wikia) for details
"    4. with silent, there is no "Hit Enter" prompt to redraw the vim screen,
"       so you've to manually refresh the screen once you return to vim.
"       that means each time you browse an url, when you return to vim,
"       you've to type :redraw! to manually refresh the blank vim screen!!!
"
"       to avoid this manual work, we pipe to redraw! (see code). vim then
"       automatically refreshes the screen after every url visit.
"       see https://goo.gl/z21rDQ (vim.wikia) for details
"
" testing:
" a) place cursor on any of the urls below
" b) press <S-:> to enter commandline
" c) type below command in the commandline:
"
"     call OpenUrlUnderCursor()
"
" test urls:
" 1. https://github.com/torvalds/pesconvert/blob/master/cairo.c#L32  blahh
" 2. https://emacs.stackexchange.com/questions/24298/can-i-eval-a-value-in-quote?rq=1
" 3. see /u/ dennis williamson @ 
"    http://stackoverflow.com/questions/2369314/why-does-sed-require-3-backslashes-for-a-regular-backslash
" 4. http://www.unix.com/shell-programming-and-scripting/137634-sed-error-unescaped-newline.html
" 5. https://goo.gl/z21rDQ
" 6. https://google.com, https://apple.com

function! OpenUrlUnderCursor()
    let l:path="/Applications/Safari.app"
    execute "normal BvEy"
    let l:url=fnameescape(matchstr(@0, '[a-z]*:\/\/[^ >,;]*'))
    if l:url != ""
        silent exec "!open -a " . l:path . " " . l:url | redraw!
        echo "opened ". l:url
    else
        echo "No URL under cursor."
    endif
endfunction


