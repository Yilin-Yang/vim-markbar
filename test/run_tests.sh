#!/bin/bash

SCRIPT_DIR=$(dirname $(readlink -f "$0"))
if [ "$(pwd)" != "$SCRIPT_DIR" ]; then
  printf "Must run this script from test subdirectory!\n"
  exit 1
fi

# Runs all test cases in this folder, using this directory's localvimrc.
#
# Taken, in part, from:
#     https://github.com/junegunn/vader.vim
#     https://github.com/neovim/neovim/issues/4842

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
  printf "\t-f <FILE>, --file=<FILE>  Run only the test <FILE>\n"
  printf "\t-e <PATH>, --vim_exe=<PATH>   Use the given (n)vim executable.\n"
  printf "\t                              Make sure to still specify --neovim if using neovim."
  printf "\n"
}

runAndExitOnFail() {
  local COMMAND=$1
  echo "$COMMAND"
  if ! eval "$COMMAND"; then
    echo "Command failed!"
    exit 1
  fi
}

# Runs an individual {TEST}. If {TEST} is a standlone-test-sequential-*
# directory, then run that subdirectory's test suite in ascending numerical
# order with a subdirectory-local viminfo/shada file.
runIndividually() {
  local BASE_CMD=$1
  local VADER_CMD=$2
  local TEST=$3
  local FILES
  FILES=$(find . -maxdepth 1 -name "$TEST" | sed "s|^\./||")
  for FILE in $FILES; do
    if [ -d "$FILE" ]; then
      runSequentialTests "$BASE_CMD" "$VADER_CMD" "$FILE"
    else
      local SINGLE_CMD="$BASE_CMD -i NONE ${VADER_CMD//\*/$FILE}"
      runAndExitOnFail "$SINGLE_CMD"
    fi
  done
}

# Runs each test in the given ${SUBDIR} in ascending numerical order.
runSequentialTests() {
  local BASE_CMD="$1"
  local VADER_CMD=$2
  local SUBDIR=$3
  local SHARED_DATA="$SUBDIR/viminfo_or_shada"

  echo "rm -f \"$SHARED_DATA\""
  rm -f "$SHARED_DATA"

  local TESTFILES
  TESTFILES=$(ls $SUBDIR/*$SUBDIR)
  for TESTFILE in $TESTFILES; do
    runAndExitOnFail "$BASE_CMD -i $SHARED_DATA ${VADER_CMD//\*/$TESTFILE}"
  done
}

# Runs test cases using the given ${BASE_CMD} and ${VADER_CMD}.
#
# Runs "all at once" tests using the given ${GLOB}, if given. If
# ${STANDALONE_GLOB} is specified, then standalone tests are run as well.
#
# ref: https://tldp.org/LDP/abs/html/string-manipulation.html
runTests() {
  local BASE_CMD=$1
  local VADER_CMD=$2
  local GLOB=$3
  local STANDALONE_GLOB=$4

  if [ "$GLOB" ]; then
    runAndExitOnFail "$BASE_CMD -i NONE ${VADER_CMD//\*/$GLOB}"
  fi
  if [ "$STANDALONE_GLOB" ]; then
    runIndividually "$BASE_CMD" "$VADER_CMD" "$STANDALONE_GLOB"
  fi
}

NVIM_PATH_DEFAULT='nvim '
VIM_PATH_DEFAULT='vim '
BASE_CMD_NVIM="--headless -Nnu .test_vimrc"
BASE_CMD_VIM="-Nnu .test_vimrc"
RUN_VIM=1
RUN_GIVEN=0
GAVE_PATH=0
export NOT_VISIBLE=1
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
      export NOT_VISIBLE=0
      BASE_CMD_NVIM="-Nnu .test_vimrc"
      BASE_CMD_VIM="-Nnu .test_vimrc"
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
    *)
      >&2 printf "Unrecognized argument: %s\n" "${ARG}"
      exit 1
  esac
  shift
done

set -p
export VADER_OUTPUT_FILE=/dev/stderr
if [ $RUN_VIM -ne 0 ]; then
  BASE_CMD=$BASE_CMD_VIM
  if [ $GAVE_PATH -ne 0 ]; then
    BASE_CMD="${EXE_PATH} ${BASE_CMD_VIM}"
  else
    BASE_CMD="${VIM_PATH_DEFAULT} ${BASE_CMD_VIM}"
  fi
  if [ $NOT_VISIBLE -eq 1 ]; then
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
    runTests "${BASE_CMD} -c 'language de_DE.utf8'" "${VADER_CMD}" "" "${GLOB_USER}"
  fi
else
  runTests "${BASE_CMD}" "${VADER_CMD}" "${GLOB_ORDINARY}" "${GLOB_STANDALONE}"
  if [ $TEST_INTERNATIONAL ]; then
    # test non-English locale
    runTests "${BASE_CMD} -c 'language de_DE.utf8'" "${VADER_CMD}" "${GLOB_ORDINARY}" "${GLOB_STANDALONE}"
  fi
fi
unset NOT_VISIBLE
