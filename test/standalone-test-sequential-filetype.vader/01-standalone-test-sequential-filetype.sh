#!/bin/bash
VIM_EXE=$1
VIM_ARGS=$2
"$VIM_EXE" $VIM_ARGS ../README.md -c "q"
exit 0
