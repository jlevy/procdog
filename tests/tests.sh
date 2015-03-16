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

# start, stop, and status on a long-lived process
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

# short-lived processes and error conditions
procdog start err1 --command "no-such-command"

procdog start err2 --command "false"
sleep 1
