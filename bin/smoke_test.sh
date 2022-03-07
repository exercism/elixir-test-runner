#!/usr/bin/env bash

set -euo pipefail

for solution in test/* ; do
  slug=$(basename $(dirname $solution))

  # create temporary output directory
  output=$(mktemp -d /tmp/output_XXXXXXXXXX)
  # run tests
  bin/run.sh $slug $solution $output
  # check result
  bin/check_files.sh $solution $output
done
