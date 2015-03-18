#!/bin/bash

# Primitive but effective test harness for running command-line regression tests.

dir=$(cd `dirname $0`; pwd)

full_log=${1:-$dir/tests-full.log}
clean_log=${2:-$dir/tests-clean.log}

echo "Running..."

rm -rf /tmp/procdog-tests
mkdir /tmp/procdog-tests
cd /tmp/procdog-tests

$dir/tests.sh >$full_log 2>&1

# Remove per-run and per-platform details to allow easy comparison.
# Use basic REs (* not +) to avoid sed flag differences between MacOS and Linux.
cat $full_log \
  | sed 's/pid=[0-9]*/pid=_PID_/g' \
  | sed 's/[0-9.:T-]*Z/_TIMESTAMP_/g' \
  | sed 's/[a-zA-Z0-9/]*procdog.cfg/_PATH_\/procdog.cfg/g' \
  | sed 's/\/private\/tmp/\/tmp/g' \
  > $clean_log

echo "Tests done."
echo
echo "Full log: $full_log"
echo "Clean log: $clean_log"
echo
echo "Validation is manual. To compare regression test results with previously correct output, run:"
echo "git diff $clean_log"
