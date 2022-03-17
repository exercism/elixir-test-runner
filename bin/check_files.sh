#!/usr/bin/env bash

set -euo pipefail

input_dir=$1
output_dir=$2

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

  if [[ ! -f "${input_dir}/expected_results.json" ]]; then
    echo "🔥 ${input_dir}: expected expected_results.json to exist 🔥"
    exit 1
  fi

  if [[ ! -f "${output_dir}/results.json" ]]; then
    echo "🔥 ${output_dir}: expected results.json to exist on successful run 🔥"
    exit 1
  fi

  if ! diff <(jq -S . ${input_dir}/expected_results.json) <(jq -S . ${output_dir}/results.json); then
    echo "🔥 ${input_dir}: expected ${output_dir}/results.json to equal ${input_dir}/expected_results.json on successful run 🔥"
    exit 1
  fi

  echo "🏁 ${input_dir}: expected files present after successful run 🏁"
}

# Check for all required dependencies
deps=(diff jq)
for dep in "${deps[@]}"; do
  installed "${dep}" || die "Missing '${dep}'"
done

main "$@"; exit
