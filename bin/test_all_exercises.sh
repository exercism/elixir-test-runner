#!/usr/bin/env bash

set -euo pipefail

# ###
# Script is to test each exercise against it's test unit individually
# against the example solution to prove the test transformation works,
#
# This works by going into a git submodule with the elixir exercises, and then 
# for each exercise running `mix test` with some options, suppressing the output,
#then tallying the results with a brief report.
#
# An exit code of 0 indicates all tests successful, 1 indicates an error with at
# least one exercise.
#
# Optionally, you can pass a list of exercise names
# to only run tests for those exercises.
# ###

# helper subroutine
function test_or_tests () {
    local tests="test"
    if (( $1 != 1 ))
    then
      tests+="s"
    fi
    printf "%s" "$tests"
}

# Initialize counts / array
test_count=0
pass_count=0
fail_count=0

failing_exercises=()

# Store the relative root dir to variable
base_dir=$(pwd)

# Getting exercises from submodule
exercises=`echo elixir/exercises/*/*`

# clean submodule for repeated local use
git submodule --quiet foreach git reset --hard
git submodule --quiet foreach git clean --force

if [[ ! -z "$@" ]]; then
  pattern=$(echo "$@" | sed 's/ /|/g')
  exercises=$(find $exercises -maxdepth 0 | grep -E "$pattern")
fi

# test each exercise
for exercise in $exercises
do
  if [ -d ${exercise} ]
  then
    cd "${exercise}"

    exercise_name=$(basename $exercise)
    test_count=$((test_count+1))

    printf "\\033[33mTesting\\033[0m: $exercise_name "

    exercise_config=".meta/config.json"
    files_to_remove=($(jq -r '.files.solution[]' "${exercise_config}"))

    # Move the example into the lib file
    for file in "${files_to_remove[@]}"
    do
      rm -r "$file"
    done

    # concept exercises have "exemplar" solutions (ideal, to be strived to)
    if [ -f .meta/exemplar.ex ]; then
      mv .meta/exemplar.ex lib/solution.ex
    fi

    # practice exercises have "example" solutions (one of many possible solutions with no single ideal approach)
    if [ -f .meta/example.ex ]; then
      mv .meta/example.ex lib/solution.ex
    fi

    # Find the exercise test files
    find "test" -type f -name '*.exs' | while read file; do
      # Skip the test_helper
      if [[ $(basename "$file") == 'test_helper.exs' ]]; then
        continue
      fi

      cp "${file}" "${file}.bkp"
      ${base_dir}/bin/exercism_test_helper --transform "${file}:${file}.altered"
      cp "${file}.altered" "${file}"
    done

    # perform tests
    test_results=$(elixir \
      -pa ${base_dir}/exercism_test_helper/_build/test/lib/exercism_test_helper/ebin \
      -S mix test \
      --seed 0 \
      --no-deps-check \
      --exclude slow)
    test_exit_code="$?"

    # based on compiler and unit test, print results
    if [ "${test_exit_code}" -eq 0 ]
    then
      printf "\\033[32mPass\\033[0m\n"
      pass_count=$((pass_count+1))
    else
      printf "\\033[31mFail\\033[0m\n"

      if [ "${compile_exit_code}" -ne 0 ]
      then
        printf "\\033[36mcompiler output\\033[0m "; printf -- '-%.0s' {1..61}; echo ""
        printf "${compiler_results}\n"
      fi
      if [ "${test_exit_code}" -ne 0 -a "${test_exit_code}" -ne 5 ]
      then
        printf "\\033[36mtest output\\033[0m "; printf -- '-%.0s' {1..65}; echo ""
        printf "${test_results}\n"
      fi
      printf -- '-%.0s' {1..80}; echo ""

      fail_count=$((fail_count+1))
      failing_exercises+=( $exercise_name )
    fi

    cd "${base_dir}"
  fi
done

# report
printf -- '-%.0s' {1..80}; echo ""
printf "${pass_count}/${test_count} tests passed.\n"

if [ "${fail_count}" -eq 0 ]
then
  # everything is good, exit
  exit 0;
else
  # There was at least one problem, list the exercises with problems.
  printf "${fail_count} $(test_or_tests "${fail_count}") failing:\n"

  for exercise in ${failing_exercises[@]}
  do
    printf " - ${exercise}\n"
  done

  exit 1;
fi
