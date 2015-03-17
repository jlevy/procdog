#!/bin/bash

# Test script. Output of this script can be saved and compared to test for regressions.

# We turn on exit on error, so that any status code changes cause a test failure.
set -e
set -o pipefail

prog=`dirname $0`/../procdog

procdog() {
  $prog --debug "$@"
}

# A trick to test for error conditions.
expect_error() {
  echo "(got expected error: status $?)"
}

# This will echo all commands as they are read. Bash commands plus their
# outputs will be used for validating regression tests pass (set -x is similar
# but less readable and sometimes not deterministic).
set -v

# Python version we're using to run tests.
python -V

# Start, stop, and status on a long-lived process.
procdog status long

procdog start long --command "sleep 5"
sleep 2

procdog status long

procdog start long --command "sleep 5"

procdog start long --command "sleep 5" --strict || expect_error

procdog stop long

procdog stop long

procdog stop long --strict || expect_error
sleep 4

# start, stop, and status on a short-lived process
procdog status short

procdog start short --command "sleep 1"
sleep 2

procdog status short

procdog start short --command "sleep 1" --strict

procdog stop long

procdog stop long --strict || expect_error

# Short-lived processes and error conditions.
procdog start err1 --command "no-such-command"

procdog start err2 --command "false"

# Redirect stdout and stderr.
rm -f tmp.stdout.* tmp.stderr.* tmp.stdin.*
procdog start out1 --command "echo hello" --stdout tmp.stdout.out1 --stderr tmp.stderr.out1
sleep 1
cat tmp.stdout.out1
cat tmp.stderr.out1

# Read from input and write stderr and stdout to same output.
echo input > tmp.stdin.out2
procdog start out2 --command "cat" --stdin tmp.stdin.out2 --stdout tmp.stdout.out2 --stderr tmp.stdout.out2
cat tmp.stdin.out2
cat tmp.stdout.out2

sleep 1
