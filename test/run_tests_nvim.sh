#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as neovim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842
# PARAM:    TEST_INTERNATIONAL  If set to '-i' or '--international', re-run
#                               tests in non-English locales.
for ARG in "$@"; do
    case $ARG in
        '-i' | '--international')
            TEST_INTERNATIONAL=1
            ;;
    esac
done

set -p
export VADER_OUTPUT_FILE=/dev/stderr
nvim --headless -Nnu .test_vimrc -i NONE -c 'Vader! *vader'

if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    nvim --headless -Nnu .test_vimrc -i NONE -c 'language de_DE.utf8' -c 'Vader! *vader'
    nvim --headless -Nnu .test_vimrc -i NONE -c 'language es_ES.utf8' -c 'Vader! *vader'
fi
