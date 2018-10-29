#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as neovim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842
# PARAM $1: RUN_FULL    If set to '-f' or '--full', re-run tests in non-English
#                       locales.
if [ "$1" == '-f' -o "$1" == '--full' ]; then
    RUN_FULL=1
fi

set -p
export VADER_OUTPUT_FILE=/dev/stderr
nvim --headless -Nnu .lvimrc -i NONE -c 'Vader! *vader'

if [ $RUN_FULL ]; then
    # test non-English locale
    nvim --headless -Nnu .lvimrc -i NONE -c 'language de_DE.utf8' -c 'Vader! *vader'
    nvim --headless -Nnu .lvimrc -i NONE -c 'language es_ES.utf8' -c 'Vader! *vader'
fi
