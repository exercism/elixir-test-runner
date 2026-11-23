#!/usr/bin/env bash

# Synopsis:
# Consolidates Elixir's own protocols, as `mix compile` does for an exercise,
# and saves them in the given directory. The Dockerfile runs this once. The
# runner puts these protocols first in the code path, so on each run it only
# has to consolidate the protocols defined or implemented by a solution.

# Arguments:
# $1: directory to write the consolidated protocols to

# Example:
# ./bin/build-consolidated.sh /opt/test-runner/consolidated

set -euo pipefail

target=$(realpath -m "$1")
project=$(mktemp -d /tmp/consolidate_XXXXXXXXXX)

cp -r test/hello-world/mix.exs test/hello-world/lib "${project}"
cd "${project}"
MIX_ENV=test mix compile --no-prune-code-paths

mkdir -p "${target}"
cp _build/test/lib/hello_world/consolidated/*.beam "${target}"
rm -r "${project}"
