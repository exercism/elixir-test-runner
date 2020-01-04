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

# Change directory to the solution folder
cd $solution_dir

# Compile solution
compile_step=$(MIX_ENV=test mix compile)

# On compilation error, create results.json with compile error, halt script with error
if [ $? -ne 0 ]; then
  printf '{"status": "fail", "message": "%q", "tests": []}\n' "${compile_step}" | sed -e 's/\("\$\x27\)\|\(\x27"\)/"/g' > "${output_dir}/results.json"
  printf "Compilation contained error, see ${output_dir}/results.json\n"
  exit 1
fi

# Move JSONFormatter and Jason beam files to submission
consolidated_dir=$(find ./_build -type d -name 'consolidated')

find "${base_dir}/json_formatter/_build" -type f -name '*.beam' | while read file; do
  echo "cp ${file} -> ${consolidated_dir}"
  cp -n "$file" "$consolidated_dir"
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
  > "${output_dir}/test_output" 2>&1
