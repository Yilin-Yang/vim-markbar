#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as "vanilla" vim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842

set -p
vim -Nnu .lvimrc -i NONE -c 'Vader! *vader'

# test non-English locale
vim -Nnu .lvimrc -i NONE -c 'language de_DE.utf8' -c 'Vader! *vader'
