#!/usr/bin/env bash

set -euo pipefail

for solution in test/* ; do
  slug=$(basename $(dirname $solution))
  # run tests
  bin/run.sh $slug $solution /tmp/solution
  # check result
  bin/check_files.sh /tmp/solution
done
