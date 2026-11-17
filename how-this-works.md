# How this works

## Goals

These are outlined in the interface that the test-runner satisfies, but briefly summarized:

- Provide automated testing feedback on every submitted exercise to exercism by a student.
- Provide detailed feedback about passing and failing tests
- Provide relevant stack traces in the event of test failure
- If the student uses print debug statements, to be able to return the io output to the student

## Components

- A `Dockerfile` which builds an image and provides an entrypoint to the test runner
- An elixir module which, when compiled, can be injected as a dependency into a solution submitted as a standard mix-style project
- An elixir module, `ExercismTestHelper.Runner`, which compiles a solution and runs its tests in a single BEAM
- A small elixir-based application compiled into an escript which performs a small transformation of the supplied test file
- Bash scripts which start the runner, and fall back to running the tests with Mix when the runner can't handle a solution

## Dockerfile

The docker image is built on hexpm's Debian-based Elixir image.

The build gets the mix-project dependencies, compiles the helper application and the escript, then provides an entry point to the bash script running as a limited user.

The build also prepares two things that every run uses:

- `bin/build-consolidated.sh` consolidates Elixir's own protocols into `/opt/test-runner/consolidated`, as `mix compile` would for an exercise.
- `bin/build-preload.sh` runs the hello-world fixture and records the modules it loads into `/opt/test-runner/preload.bin` (see "Preloading modules" below).

## Elixir module - JSONFormatter

> found at `exercism_test_helper/lib/json_formatter.ex`

This test-runner uses Elixir-Lang's ExUnit testing framework to run all of the tests through the `mix test` task.

It leverages the `mix test` formatter option, where an alternate to ExUnit's `CLIFormatter` can be specified. The alternate formatter is compiled, then inserted into the compiled submission's compiled beam files so that at run-time it can be loaded as a dependency.

The formatter is based on the ExUnit's [formatter specification](https://hexdocs.pm/ex_unit/1.7.0/ExUnit.Formatter.html). It is, itself, an instance of a GenServer running under the ExUnit supervisor listening for events to then log. When the suite completes, it then outputs the log to a formatted JSON specified by the System ENV `JSON_REPORT_FILE` (`results.json` by default) to the directory specified by `JSON_REPORT_DIR` (`Mix.Project.app_path()` by default).

Other options supported by the formatter via System ENV

- `JSON_PREPEND_PROJECT_NAME` adds the project name to the report file name
- `JSON_PRINT_FILE` prints out a summary of the report to `:stderr`

## Elixir application escript

The escript creates a discrete way for the shell script to start the elixir application and perform 4 operations necessary for this test-runner service to work

### cli.ex

> `exercism_test_helper/lib/exercism_test_helper/cli.ex`

The entrypoint into the escript as defined in the `mix.exs` file.

Supports command-line options indicating a command to perform:

```text
  Usage:
  > exercism_test_helper [--parse-meta <test filename>:<output json filename>]
  > exercism_test_helper [--transform <test filename>:<transformed test filename>]
  > exercism_test_helper [--log-to-json <output filename>:<output json filename>]
  > exercism_test_helper [--combine <result json>:<metadata json>:<output json>]
```

At this time they are each run separately as single steps and it does not support a multistep process.

### test_transformer.ex

> `exercism_test_helper/lib/test_source/transformer.ex`

One caveat with the ExUnit testing framework is that supervisor is run in a process separate from the tests separate from the formatters. So it isn't possible to guarantee that a `IO.puts` or `IO.inspect` function call would appear in the correct order since they are all being called asynchronously to an asynchronous io process.

So this module can take a test suite, read it, compile it to an AST [Abstract Syntax Tree] format, where it inserts a `IO.puts` function call to `:stdio` at the start of every test case to print a header with the test name.

The outcome is that when the test suite is run, since the default CLIFormatter output is suppressed, the test prints the header, runs the test which may or may not have further output from the user's code so that it can be parsed and the output attributed to each test case.

#### Why this method and not another

- The first reason is because of the multi-process design of ExUnit previously discussed
- In Elixir, it is not possible to monkey patch a function (as can often be done in other languages) so we needed to find a way to work around this

#### Yes, but there is a simpler way

Awesome! Raise an issue, let's discuss!

## Running the tests in one BEAM

> `exercism_test_helper/lib/exercism_test_helper/runner.ex`

Most of a short test run goes on starting BEAMs and loading Elixir. Running the tests with Mix and the escript starts seven BEAMs per run. `ExercismTestHelper.Runner` does the same work in one BEAM, without Mix:

1. It checks that the project has the shape used by the track's exercises: a standard `mix.exs` with no dependencies, no `config/` directory, one test file plus `test/test_helper.exs`, and no use of `Mix` in the code.
1. In a second process, it parses the test metadata and transforms the test file. Meanwhile it compiles `lib/` with `Kernel.ParallelCompiler`.
1. It writes the `.app` file and starts the application, as `mix compile` would.
1. It consolidates only the protocols defined or implemented by the solution. Elixir's own protocols were consolidated when the image was built. Consolidating every protocol, as `mix compile` does, takes a large part of a run.
1. It runs ExUnit with the options set by `mix test --seed 0 --exclude slow --formatter JSONFormatter`.
1. It builds `results.json` with the same code as the escript's `--log-to-json` and `--combine` commands.

### Preloading modules

> `exercism_test_helper/lib/exercism_test_helper/preload.ex`

A run loads over 200 modules from disk. `ExercismTestHelper.Preload` starts as soon as the VM boots and loads them in a background process, in the order the runner needs them. The runner meanwhile gets on with its first steps on the other CPU. The list of modules is recorded when the image is built.

### Falling back to Mix

The runner exits with code 100 if the solution isn't a standard exercise project, or if it crashes. `bin/run.sh` then runs `bin/run-with-mix.sh`, which runs the tests with Mix and the escript as described below.

The runner exits with code 101 if the solution fails to compile. `bin/run.sh` then runs `mix compile`, so that the student sees Mix's own error message.

## Shell script entry point

> `bin/run.sh`

This serves as the test-runner's entry point once the image is built. It copies the solution to a temporary directory and starts `ExercismTestHelper.Runner` with `erl`. Calling `erl` directly with the arguments built by the `elixir` script saves the time spent in that script.

> `bin/run-with-mix.sh`

This runs the tests with Mix, for the solutions the runner doesn't handle. It follows this basic sequence:

1. Parse metadata from the test suite
1. Transform a test suite to make suitable for output capture
1. Compile and run the test suite, capturing stdout and stderr to file
1. Transform the stdout log into a JSON suitable for combining with the results
1. Combining the output, metadata, and results JSON files into a final results.json file.
