#!/usr/bin/env bash

# Synopsis:
# Automatically tests exercism's Elixir track solutions against corresponding test files.
# Takes three arguments and makes sure all the tests are run

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the tests output to the output directory

# Example:
# ./bin/run.sh two-fer path/to/two-fer/solution/folder path/to/output-directory

# This script compiles the solution and runs its tests in a single BEAM, with
# ExercismTestHelper.Runner (see how-this-works.md). The runner only handles the
# project shape used by the track's exercises. For anything else (for example a
# mix.exs with dependencies, a config/ directory, or code that calls Mix), it
# exits with code 100, and the tests run with Mix as they did before
# (bin/run-with-mix.sh). "Falling back to Mix" in how-this-works.md lists every case.

base_dir=$(pwd)
solution_dir=$(realpath "$2")
output_dir=$(realpath "$3")

# Copy solution to /tmp
tmp_sol=$(mktemp -d /tmp/solution_XXXXXXXXXX)
cp -r "${solution_dir}"/* "${tmp_sol}"
cd "${tmp_sol}"

# The hexpm Docker images install Elixir here.
elixir_dir=/usr/local/lib/elixir
helper_build="${base_dir}/exercism_test_helper/_build/test/lib"

# The runner hands a project with any of these directories to Mix (see
# ExercismTestHelper.Runner). Checking for them here saves starting a BEAM that
# would only exit, which costs about 0.5s per run.
if [[ -e _build || -e deps || -e config || -e src ]]; then
  cd "${base_dir}"
  exec "${base_dir}/bin/run-with-mix.sh" "$1" "${solution_dir}" "${output_dir}"
fi

# Start the BEAM with `erl`, with the arguments the `elixir` script would pass.
# Going through the `elixir` script would cost extra time on every run.
# The runner's stdout becomes the tests' output, as with `mix test > output`.
EXERCISM_CONSOLIDATED="${base_dir}/consolidated" \
EXERCISM_PRELOAD="${base_dir}/preload.bin" \
JSON_REPORT_DIR="${tmp_sol}" \
  erl -noshell \
  -elixir_root "${elixir_dir}/lib" -pa "${elixir_dir}/lib/elixir/ebin" \
  -pa "${helper_build}/exercism_test_helper/ebin" -pa "${helper_build}/jason/ebin" \
  -s Elixir.ExercismTestHelper.Preload start \
  -s Elixir.ExercismTestHelper.Runner start \
  > "${tmp_sol}/output" 2> "${tmp_sol}/error_log"

case $? in
  0)
    # The runner finished. There is no results.json if the test file failed to compile.
    if [[ -f "${tmp_sol}/results.json" && "${tmp_sol}" != "${output_dir}" ]]; then
      cp "${tmp_sol}/results.json" "${output_dir}/results.json"
    fi
    exit 0
    ;;
  101)
    # The solution failed to compile. Run `mix compile` so that the student
    # sees Mix's own error message, as before. This calls `erl` with exactly
    # the arguments built by the `mix` and `elixir` scripts, to skip the cost
    # of those scripts. If Mix compiles the solution without an error, the
    # tests will run with Mix below.
    rm -rf "${tmp_sol}/_build"
    compile_step=$(MIX_ENV=test erl -noshell \
      -elixir_root "${elixir_dir}/bin/../lib" -pa "${elixir_dir}/bin/../lib/elixir/ebin" \
      -s elixir start_cli -extra /usr/local/bin/mix compile --no-prune-code-paths 2>&1)

    if [ $? -ne 0 ]; then
      jo version=3 status=error message="${compile_step}" tests="[]" > "${output_dir}/results.json"
      printf "Compilation contained error, see %s/results.json\n" "${output_dir}"
      exit 0
    fi
    ;;
esac

# Exit code 100 (or a crash) means the solution doesn't have the standard
# exercise shape (see "Falling back to Mix" in how-this-works.md).
cd "${base_dir}"
exec "${base_dir}/bin/run-with-mix.sh" "$1" "${solution_dir}" "${output_dir}"
