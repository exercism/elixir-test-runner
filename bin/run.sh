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
  cat "${file}" | awk -f ./scripts/get_meta.awk > "${output_dir}/metadata.csv"

  printf "transforming %q\n" "${file}"
  ./bin/exercism_test_helper --transform "${file}" --replace
done

# Change directory to the solution folder
cd $solution_dir

# Compile solution
compile_step=$(MIX_ENV=test mix compile)

# On compilation error, create results.json with compile error, halt script with error
if [ $? -ne 0 ]; then
  jo status=fail message="${compile_step}" tests="[]" > "${output_dir}/results.json"
  printf "Compilation contained error, see ${output_dir}/results.json\n"
  exit 0
fi

# Move JSONFormatter and Jason beam files to submission
consolidated_dir=$(find ./_build -type d -name 'consolidated')

find "${base_dir}/exercism_test_helper/_build" -type f -name '*.beam' | while read file; do
  echo "cp ${file} -> ${consolidated_dir}"
  cp -f "$file" "$consolidated_dir"
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
./bin/exercism_test_helper --log-to-json "${output_dir}/output"

# Convert the metadata CSV to json
./bin/exercism_test_helper --parse-meta-csv "${output_dir}/metadata.csv:${output_dir}/metadata.json"

# Combine the results and output log json
./bin/exercism_test_helper --combine "${output_dir}/results.json:${output_dir}/metadata.json:${output_dir}/output.json"
