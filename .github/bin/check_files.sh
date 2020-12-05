#!/usr/bin/env bash

set -euo pipefail

function main {
  expected_files=(metadata.json output error_log results.json output.json)

  for file in ${expected_files[@]}; do
    if [[ ! -f "./test/${file}" ]]; then
      echo "🔥 expected ${file} to exist on successful run 🔥"
      exit 1
    fi
  done
}

main "$@"; exit