#!/bin/bash

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

# Save pwd
base_dir=$(pwd)
solution_dir=$(realpath $2)
output_dir=$(realpath $3)

# Copy solution to /tmp
tmp_sol=$(mktemp -d /tmp/solution_XXXXXXXXXX)
cp -r ${solution_dir}/* ${tmp_sol}
solution_dir=${tmp_sol}

printf "transforming %q\n" "${solution_dir}/mix.exs"
./bin/exercism_test_helper --transform-mix "${solution_dir}/mix.exs:${solution_dir}/mix.exs"

# Find the exercise test files
find "${solution_dir}/test" -type f -name '*.exs' | while read file; do
  # Skip the test_helper
  if [[ $(basename "$file") == 'test_helper.exs' ]]; then
    continue
  fi

  printf "parsing %q for metadata\n" "${file}"
  ./bin/exercism_test_helper --parse-meta "${file}:${solution_dir}/metadata.json"

  printf "transforming %q\n" "${file}"
  ./bin/exercism_test_helper --transform "${file}:${file}"
done

# Change directory to the solution folder
cd $solution_dir

# Compile solution
compile_step=$(MIX_ENV=test mix compile)

# On compilation error, create results.json with compile error, halt script with error
if [ $? -ne 0 ]; then
  jo version=3 status=error message="${compile_step}" tests="[]" > "${output_dir}/results.json"
  printf "Compilation contained error, see ${output_dir}/results.json\n"
  exit 0
fi

# Run submission test
export JSON_PRINT_FILE=1
export JSON_REPORT_DIR="${solution_dir}"

elixir \
  -pa ${base_dir}/exercism_test_helper/_build/test/lib/exercism_test_helper/ebin \
  -pa ${base_dir}/exercism_test_helper/_build/test/lib/jason/ebin \
  -S mix test \
  --seed 0 \
  --no-deps-check \
  --exclude slow \
  --formatter JSONFormatter \
  > "${solution_dir}/output" 2> "${solution_dir}/error_log"

cd $base_dir

# Convert the output log to json
./bin/exercism_test_helper --log-to-json "${solution_dir}/output:${solution_dir}/output.json"

# Combine the results and output log json
./bin/exercism_test_helper --combine "${solution_dir}/results.json:${solution_dir}/metadata.json:${solution_dir}/output.json"

# Copy result to output directory if required
if [[ $solution_dir != $output_dir ]]; then
  cp "${solution_dir}/results.json" "${output_dir}/results.json"
fi
