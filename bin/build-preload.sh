#!/usr/bin/env bash

# Synopsis:
# Builds the list of modules that ExercismTestHelper.Preload loads in the
# background at the start of every run. It runs the hello-world fixture and
# records the modules the runner loads, in the order it first needs them.
# The Dockerfile runs this once, after bin/build-consolidated.sh.

# Arguments:
# $1: path of the list to write

# Example:
# ./bin/build-preload.sh /opt/test-runner/preload.bin

set -euo pipefail

target=$(realpath -m "$1")
output=$(mktemp -d /tmp/preload_output_XXXXXXXXXX)

EXERCISM_RECORD_PRELOAD="${target}" bin/run.sh hello-world test/hello-world "${output}"

rm -r "${output}"

# The runner only writes the list if it ran the tests itself.
if [[ ! -f "${target}" ]]; then
  echo "The runner fell back to Mix, so no preload list was written" >&2
  exit 1
fi
