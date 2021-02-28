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

# Find the exercise test files
find "${solution_dir}/test" -type f -name '*.exs' | while read file; do
  # Skip the test_helper
  if [[ $(basename "$file") == 'test_helper.exs' ]]; then
    continue
  fi

  printf "parsing %q for metadata\n" "${file}"
  ./bin/exercism_test_helper --parse-meta "${file}:${output_dir}/metadata.json"

  printf "transforming %q\n" "${file}"
  cp "${file}" "${file}.bkp"
  ./bin/exercism_test_helper --transform "${file}:${file}.altered"
  cp "${file}.altered" "${file}"
done

# Change directory to the solution folder
cd $solution_dir

# Compile solution
compile_step=$(MIX_ENV=test mix compile)

# On compilation error, create results.json with compile error, halt script with error
if [ $? -ne 0 ]; then
  jo status=error message="${compile_step}" tests="[]" > "${output_dir}/results.json"
  printf "Compilation contained error, see ${output_dir}/results.json\n"
  exit 0
fi

# Move JSONFormatter and Jason beam files to submission
ebin_dir=$(find ./_build/test -type d -name 'ebin' | head -n 1)

find "${base_dir}/exercism_test_helper/_build/test" -type f -name '*.beam' | while read file; do
  echo "cp ${file} -> ${ebin_dir}"
  cp -f "${file}" "${ebin_dir}"
done

# Run submission test
export JSON_PRINT_FILE=1
export JSON_REPORT_DIR="$output_dir"

mix test \
  --seed 0 \
  --no-compile \
  --no-deps-check \
  --include pending:true \
  --formatter JSONFormatter \
  > "${output_dir}/output" 2> "${output_dir}/error_log"

cd $base_dir

# Convert the output log to json
./bin/exercism_test_helper --log-to-json "${output_dir}/output:${output_dir}/output.json"

# Combine the results and output log json
./bin/exercism_test_helper --combine "${output_dir}/results.json:${output_dir}/metadata.json:${output_dir}/output.json"

# Restore test files
find "${solution_dir}/test" -type f -name '*.exs' | while read file; do
  # Skip the test_helper
  if [[ $(basename "$file") == 'test_helper.exs' ]]; then
    continue
  fi

  printf "restoring %q\n" "${file}"
  cp "${file}.bkp" "${file}"
done
