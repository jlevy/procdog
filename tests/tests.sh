#!/bin/bash

# Test script. Output of this script can be saved and compared to test for regressions.
# Double-spacing between commands here makes the script output easier to read.

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

config_file=`dirname $0`/procdog.cfg

# This will echo all commands as they are read. Bash commands plus their
# outputs will be used for validating regression tests pass (set -x is similar
# but less readable and sometimes not deterministic).
set -v

# Python version we're using to run tests.
python -V

# Error invocations.
procdog blah || expect_error

procdog status || expect_error

procdog status foo@bar || expect_error

# Start, stop, and status on a long-lived process.
procdog status long || expect_error

procdog wait long || expect_error

procdog start long --command "sleep 5" --health-command "true"
sleep 2

# Check sock and lock files.
ls -1 /var/tmp/procdog.long.*

procdog status long

procdog wait long

procdog start long --command "sleep 5" --health-command "true"

procdog start long --command "sleep 5" --health-command "true" --strict || expect_error

procdog stop long

ls -1 /var/tmp/procdog.long.*

procdog stop long

procdog stop long --strict || expect_error
sleep 4

# Start, stop, and status on a short-lived process.
procdog status short || expect_error

procdog start short --command "sleep 1"
sleep 2

procdog status short || expect_error

procdog start short --command "sleep 1" --strict

procdog stop short

procdog stop short --strict || expect_error

# A long-lived unhealthy process.
procdog wait unhealthy1 || expect_error

procdog start unhealthy1 --command "sleep 100" --health-command "false"

procdog wait unhealthy1 || expect_error

procdog stop unhealthy1

# Test --ensure-healthy.
procdog start ensure1 --command "sleep 100" --health-command "true" --ensure-healthy

procdog stop ensure1

procdog start ensure2 --command "sleep 100" --health-command "false" --ensure-healthy || expect_error

# Test that a slow health check doesn't affect listening.
procdog start slow-health --command "sleep 100" --health-command "sleep 4" >/dev/null 2>&1 &

# We sleep only a little so the previous command is certain to get the file lock first.
sleep 0.1
procdog start slow-health --command "sleep 100" --health-command "sleep 4"

procdog status slow-health

procdog stop slow-health


# Short-lived processes and error conditions.
rm -f tmp.stdout.* tmp.stderr.* tmp.stdin.*

procdog start err1 --command "no-such-command" || expect_error

procdog start err2 --command "false" || expect_error

procdog start pwd --command "pwd" --stdout tmp.stdout.pwd || expect_error
tail -1 tmp.stdout.pwd

procdog start pwd --command "pwd" --stdout tmp.stdout.pwd --dir /tmp || expect_error
tail -1 /tmp/tmp.stdout.pwd

# Redirect stdout and stderr. Environment variables.
export TESTENV=wensleydale
procdog start out1 --command 'echo hello $TESTENV' --stdout tmp.stdout.out1 --stderr tmp.stderr.out1 || expect_error
sleep 1
cat tmp.stdout.out1
cat tmp.stderr.out1
rm -f tmp.stdout.* tmp.stderr.* tmp.stdin.*

procdog start out1 --command 'echo hello $BADENVVAR' --stdout tmp.stdout.out1 --stderr tmp.stderr.out1 || expect_error

# Read from input and write stderr and stdout to same output.
echo input > tmp.stdin.out2
procdog start out2 --command "cat" --stdin tmp.stdin.out2 --stdout tmp.stdout.out2 --stderr tmp.stdout.out2 || expect_error
cat tmp.stdin.out2
cat tmp.stdout.out2

# Configuration tests.
procdog start conftest --config $config_file

procdog stop conftest --config $config_file

procdog start conftest_bad --config $config_file || expect_error

# Done!
