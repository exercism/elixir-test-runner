#!/usr/bin/env bash

set -euo pipefail

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
