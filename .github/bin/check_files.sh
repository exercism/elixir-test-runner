#!/usr/bin/env bash

set -euo pipefail

exercise=$1

function installed {
  cmd=$(command -v "${1}")

  [[ -n "${cmd}" ]] && [[ -f "${cmd}" ]]
  return ${?}
}

function die {
  >&2 echo "Fatal: ${@}"
  exit 1
}

function main {
  expected_files=(metadata.json output error_log results.json output.json)

  for file in ${expected_files[@]}; do
    if [[ ! -f "./test/${exercise}/${file}" ]]; then
      echo "🔥 ${exercise}: expected ${file} to exist on successful run 🔥"
      exit 1
    fi
  done

  if ! diff <(jq -S . ./test/${exercise}/expected_results.json) <(jq -S . ./test/${exercise}/results.json); then
    echo "🔥 ${exercise}: expected ./test/${exercise}/results.json to equal ./test/${exercise}/expected_results.json on successful run 🔥"
    exit 1
  fi

  echo "🏁 ${exercise}: expected files present after successful run 🏁"
}

# Check for all required dependencies
deps=(diff jq)
for dep in "${deps[@]}"; do
  installed "${dep}" || die "Missing '${dep}'"
done

main "$@"; exit
