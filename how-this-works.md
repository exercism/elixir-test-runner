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
- A small elixir-based application compiled into an escript which performs a small tranformation of the supplied test file
- A bash script which coordinates the acitivities of the escript, test-suite run, and result output.

## Dockerfile

## Elixir module

## Elixir application escript

## Shell script entry point
