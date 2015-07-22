#!/bin/bash

# Primitive but effective test harness for running command-line regression tests.

dir=$(cd `dirname $0`; pwd)

full_log=${1:-$dir/tests-full.log}
clean_log=${2:-$dir/tests-clean.log}

echo "Running..."

rm -rf /tmp/procdog-tests
mkdir /tmp/procdog-tests
cd /tmp/procdog-tests

# Hackity hack:
# Remove per-run and per-platform details to allow easy comparison.
# Update these patterns as appropriate.
# Note we use perl not sed, so it works on Mac and Linux. The $|=1; is just for the impatient and ensures line buffering.
$dir/tests.sh 2>&1 | tee $full_log \
  | perl -pe '$|=1; s/pid=[0-9]*/pid=_PID_/g' \
  | perl -pe '$|=1; s/[0-9.:T-]*Z/_TIMESTAMP_/g' \
  | perl -pe '$|=1; s/[a-zA-Z0-9\/]*procdog.cfg/_PATH_\/procdog.cfg/g' \
  | perl -pe '$|=1; s/\/private\/tmp/\/tmp/g' \
  | perl -pe '$|=1; s/procdog [(][0-9]*[)]/procdog (_PID_)/g' \
  | tee $clean_log

echo "Tests done."
echo
echo "Full log: $full_log"
echo "Clean log: $clean_log"
echo
echo "Validation is manual. To compare regression test results with previously correct output, run:"
echo "git diff $clean_log"
