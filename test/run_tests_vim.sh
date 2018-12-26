#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as "vanilla" vim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842
# PARAM:    TEST_INTERNATIONAL  If set to '-i' or '--international', re-run
#                               tests in non-English locales.
BASE_CMD="vim -Nnu .test_vimrc -i NONE"
TEST_CMD="-c 'Vader! test*vader'"
export VISIBLE=0
for ARG in "$@"; do
    case $ARG in
        '-i' | '--international')
            TEST_INTERNATIONAL=1
            ;;
        '-v' | '--visible')
            export VISIBLE=1
            BASE_CMD="vim -Nnu .test_vimrc -i NONE"
            TEST_CMD="-c 'Vader test*vader'"
            ;;
    esac
done

set -p
echo "${BASE_CMD} ${TEST_CMD}"
eval "${BASE_CMD} ${TEST_CMD}"

if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    eval "${BASE_CMD} -c 'language de_DE.utf8' ${TEST_CMD}"
    eval "${BASE_CMD} -c 'language es_ES.utf8' ${TEST_CMD}"
fi
