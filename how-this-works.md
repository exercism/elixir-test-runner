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
- A small elixir-based application compiled into an escript which performs a small transformation of the supplied test file
- A bash script which coordinates the activities of the escript, test-suite run, and result output.

## Dockerfile

Described in bread strokes, the docker image is build on an alpine linux variant with elixir pre-built.

The build script gets the mix-project dependencies, compiles the Formatter and escript, then provides an entry point to the bash script running as a limited user.

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

## Shell script entry point

> `bin/run.sh`

This serves as the test-runner's entry point once the image is built. It follows this basic sequence:

1. Parse metadata from the test suite
1. Transform a test suite to make suitable for output capture
1. Compile and run the test suite, capturing stdout and stderr to file
1. Transform the stdout log into a JSON suitable for combining with the results
1. Combining the output, metadata, and results JSON files into a final results.json file.
