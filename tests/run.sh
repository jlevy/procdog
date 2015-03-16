#!/bin/bash

# Primitive but effective test harness for running command-line regression tests.

dir=`dirname $0`

full_log=${1:-$dir/tests-full.log}
clean_log=${2:-$dir/tests-clean.log}

echo "Running..."
$dir/tests.sh >$full_log 2>&1

# Use basic REs (* not +) to avoid sed flag differences between MacOS and Linux.
cat $full_log \
  | sed 's/pid=[0-9]*/pid=_PID_/g' \
  > $clean_log

echo "Tests done."
echo
echo "Full log: $full_log"
echo "Clean log: $clean_log"
echo
echo "Validation is manual. To compare regression test results with previously correct output, run:"
echo "git diff $clean_log"
