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

  if ! jq -S .version ./test/expected_results.json; then
    echo "🔥 jq cannot read file ./test/expected_results.json 🔥"
    exit 1
  fi

  if ! diff <(jq -S . ./test/expected_results.json) <(jq -S . ./test/results.json); then
    echo "🔥 expected ./test/results.json to equal ./test/expected_results.json on successful run 🔥"
    exit 1
  fi

  echo "🏁 expected files present after successful run 🏁"
}

main "$@"; exit
