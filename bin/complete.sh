#!/usr/bin/env bash

# run this from the base_dir

set -euo pipefail

cd exercism_test_helper
MIX_ENV=prod mix escript.build
mv exercism_test_helper ../bin
cd ..
./bin/run.sh a ./test/hello-world ./test