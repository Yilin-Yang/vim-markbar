#!/bin/bash
VIM_EXE=$1
VIM_ARGS=$2
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'if &filetype !=# "markdown" | cquit! | else | quit | endif'
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'call feedkeys("i" . getbufvar("%", "&filetype"), "n")'
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'call feedkeys("i" . bufnr("%"), "n")'
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'autocmd VimEnter * call feedkeys("i" . bufnr("%"), "n")'
"$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'call feedkeys(":if &filetype !=# \"markdown\" | cquit! | else | quit | endif\<cr>", "n")'
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'if v:false | cquit! | else | quit | endif'
# "$VIM_EXE" $VIM_ARGS -c 'call feedkeys(":edit ../README.md\<cr>", "n")' -c 'echomsg &filetype'
exit $?
