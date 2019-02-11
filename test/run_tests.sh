#!/bin/bash

# EFFECTS:  Runs all test cases in this folder, using this directory's
#           localvimrc as well as neovim.
# DETAILS:  Taken, in part, from:
#               https://github.com/junegunn/vader.vim
#               https://github.com/neovim/neovim/issues/4842
# PARAM:    TEST_INTERNATIONAL  If set to '-i' or '--international', re-run
#                               tests in non-English locales.
printUsage() {
  echo "USAGE: ./run_tests.sh [--vim | --neovim] [-v|--visible] [-h|--help] [-i|--international] [-f <FILE_PAT> | --file=<FILE_PAT>] [-e <VIM_PATH> | --vim_exe=<VIM_PATH>]"
  echo ""
  echo "Run test cases for this plugin."
  echo ""
  echo "Arguments:"
  printf "\t--vim | --neovim    Whether to run tests using vim or neovim\n"
  printf "\t-v, --visible       Whether to run tests in an interactive vim instance\n"
  printf "\t                    (Script will not fail with nonzero exit code on test failure)\n"
  printf "\t-h, --help           Print this helptext\n"
  printf "\t-i, --international  Re-run tests using non-English locales\n"
  printf "\t-f <PAT>, --file=<PAT>   Run only tests globbed (matched) by <PAT>\n"
  printf "\t-v <PATH>, --vim_exe=<PATH>   Use the given (n)vim executable.\n"
  printf "\t                              Unaffected by --vim or --neovim"
  printf "\n"
}

runAndExitOnFail() {
  local COMMAND=$1
  echo "$COMMAND"
  eval "$COMMAND"
  if [[ $? -ne 0 ]]; then
    echo "Command failed!"
    exit 1
  fi
}

# Runs the given ${COMMAND}, substituting the '*' character in ${COMMAND} with
# the given ${GLOB}.
runAllAtOnce() {
  local COMMAND=$1
  local GLOB=$2
  local COMMAND="${COMMAND//\*/$GLOB}"
  runAndExitOnFail "$COMMAND"
}

# Runs the given ${COMMAND}, substituting the '*' character in ${COMMAND} with
# all of the files matched by the given ${GLOB}.
runIndividually() {
  local COMMAND=$1
  local GLOB=$2
  local FILES
  FILES=$(ls $GLOB)
  for FILE in $FILES; do
    local SINGLE_CMD="${COMMAND//\*/$FILE}"
    runAndExitOnFail "$SINGLE_CMD"
  done
}

# Runs test cases using the given ${BASE_CMD} and ${VADER_CMD}, but inserts
# the given ${BEFORE} command between ${BASE_CMD} and ${VADER_CMD}.
#
# Runs "all at once" tests using the given ${GLOB}. If ${STANDALONE_GLOB} is
# specified, standalone tests are run as well.
runTests() {
  local BASE_CMD=$1
  local VADER_CMD=$2
  local BEFORE=$3
  local GLOB=$4
  local STANDALONE_GLOB=$5

  local COMMAND="$BASE_CMD $BEFORE $VADER_CMD"
  runAllAtOnce "$COMMAND" "$GLOB"
  if [ "$STANDALONE_GLOB" ]; then
    runIndividually "$COMMAND" "$STANDALONE_GLOB"
  fi
}

NVIM_PATH_DEFAULT='nvim '
VIM_PATH_DEFAULT='vim '
BASE_CMD_NVIM="--headless -Nnu .test_vimrc -i NONE"
BASE_CMD_VIM="-Nnu .test_vimrc -i NONE"
RUN_VIM=1
RUN_GIVEN=0
GAVE_PATH=0
export VISIBLE=0
VADER_CMD="-c 'Vader! *'"
GLOB_ORDINARY='test-*.vader'
GLOB_STANDALONE='standalone-test-*.vader'
while [[ $# -gt 0 ]]; do
  ARG=$1
  case $ARG in
    '-i' | '--international')
      TEST_INTERNATIONAL=1
      ;;
    '-v' | '--visible')
      export VISIBLE=1
      BASE_CMD_NVIM="nvim -Nnu .test_vimrc -i NONE"
      BASE_CMD_VIM="vim -Nnu .test_vimrc -i NONE"
      VADER_CMD="-c 'Vader *'"
      ;;
    '--vim')
      RUN_VIM=1
      ;;
    '--neovim')
      RUN_VIM=0
      ;;
    '--file='*)
      GLOB_USER="${ARG#*=}"
      RUN_GIVEN=1
      ;;
    '-f')
      GLOB_USER="$2"
      RUN_GIVEN=1
      shift  # past pattern
      ;;
    '--vim_exe='*)
      EXE_PATH="${ARG#*=}"
      GAVE_PATH=1
      shift
      ;;
    '-e')
      EXE_PATH="$2"
      GAVE_PATH=1
      shift
      ;;
    "-h")
      printUsage
      exit 0
      ;;
    "--help")
      printUsage
      exit 0
      ;;
  esac
  shift
done
export IS_TYPEVIM_DEBUG=1

set -p
export VADER_OUTPUT_FILE=/dev/stderr
if [ $RUN_VIM -ne 0 ]; then
  BASE_CMD=$BASE_CMD_VIM
  if [ $GAVE_PATH -ne 0 ]; then
    BASE_CMD="${EXE_PATH} ${BASE_CMD_VIM}"
  else
    BASE_CMD="${VIM_PATH_DEFAULT} ${BASE_CMD_VIM}"
  fi
  if [ $VISIBLE -eq 0 ]; then
    VADER_CMD="$VADER_CMD > /dev/null"
  fi
else
  if [ $GAVE_PATH -ne 0 ]; then
    BASE_CMD="${EXE_PATH} ${BASE_CMD_NVIM}"
  else
    BASE_CMD="${NVIM_PATH_DEFAULT} ${BASE_CMD_NVIM}"
  fi
fi

if [ $RUN_GIVEN -eq 1 ]; then
  runTests "${BASE_CMD}" "${VADER_CMD}" "" "${GLOB_USER}"
  if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    runTests "${BASE_CMD}" "${VADER_CMD}" "-c 'language de_DE.utf8'" "${GLOB_USER}"
    runTests "${BASE_CMD}" "${VADER_CMD}" "-c 'language es_ES.utf8'" "${GLOB_USER}"
  fi
else
  runTests "${BASE_CMD}" "${VADER_CMD}" "" "${GLOB_ORDINARY}" "${GLOB_STANDALONE}"
  if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    runTests "${BASE_CMD}" "${VADER_CMD}" "-c 'language de_DE.utf8'" "${GLOB_ORDINARY}" "${GLOB_STANDALONE}"
    runTests "${BASE_CMD}" "${VADER_CMD}" "-c 'language es_ES.utf8'" "${GLOB_ORDINARY}" "${GLOB_STANDALONE}"
  fi
fi
unset IS_TYPEVIM_DEBUG
unset VISIBLE
