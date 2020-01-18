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

#transform the test files
find "${solution_dir}/test" -type f -name '*.exs' | while read file; do
  if [[ $(basename "$file") == 'test_helper.exs' ]]; then
    continue
  fi

  printf "transforming %q\n" "${file}"
  ./bin/exercism_formatter --transform "${file}" --replace
done

# Change directory to the solution folder
cd $solution_dir

# Compile solution
compile_step=$(MIX_ENV=test mix compile)

# On compilation error, create results.json with compile error, halt script with error
if [ $? -ne 0 ]; then
  compile_step=$(printf "${compile_step}" | tr '"' '`')
  printf '{"status": "fail", "message": "%q", "tests": []}\n' "${compile_step}" | sed -e 's/\("\$\x27\)\|\(\x27"\)/"/g' > "${output_dir}/results.json"
  printf "Compilation contained error, see ${output_dir}/results.json\n"
  exit 1
fi

# Move JSONFormatter and Jason beam files to submission
consolidated_dir=$(find ./_build -type d -name 'consolidated')

find "${base_dir}/exercism_formatter/_build" -type f -name '*.beam' | while read file; do
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
./bin/exercism_formatter --log-to-json "${output_dir}/output"

# Combine the results and output log json
./bin/exercism_formatter --combine "${output_dir}/results.json:${output_dir}/output.json"
