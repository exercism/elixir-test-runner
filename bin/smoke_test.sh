#!/usr/bin/env bash

set -e # Make script exit when a command fail.
set -u # Exit on usage of undeclared variable.
# set -x # Trace what gets executed.
set -o pipefail # Catch failures in pipes.

for solution in test/* ; do
  slug=$(basename $(dirname $solution))

  mkdir -p /tmp/${solution}
  rm -rf /tmp/${solution}
  cp -r ${solution} /tmp/${solution}
  solution=/tmp/${solution}

  # run tests
  bin/run.sh $slug $solution $solution
  # check result
  bin/check_files.sh $solution
done
