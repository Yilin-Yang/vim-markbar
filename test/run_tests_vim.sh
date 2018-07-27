#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as "vanilla" vim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim

vim -Nu .lvimrc +Vader*
