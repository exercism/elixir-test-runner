# ElixirTestRunner

![](https://github.com/exercism/elixir-test-runner/workflows/Elixir%20CI/badge.svg)

Exercism Automated Test Runner for Elixir Exercises

## Environment

The test runner currently targets exercises supporting Elixir >= 1.6 and Erlang/OTP >= 20, but is running on Elixir 1.15.2 on hexpm's `elixir:1.15.2-erlang-26.0.2-debian-bookworm-20230612` image

The `Dockerfile` also has added `bash`, `jo` and `jq` to the image.

## Testing

---

> It is recommended to test BEFORE submitting a PR. It will test your submission, ensure
> that the repository builds as a whole, and help guard against unintentional, unrelated changes.

---

## Contributing Guide

For an in-depth discussion of how exercism language tracks and exercises work, please see [CONTRIBUTING.md](https://github.com/exercism/elixir-test-runner/blob/master/CONTRIBUTING.md)

## Documentation "How does this thing work?"

For a -- hopefully -- in-depth discussion of how this repo fits inside of the larger automated testing framework, see [exercism's automated testing repo](https://github.com/exercism/automated-tests)

- The interface the tester needs to satisfy --> [interface](https://exercism.org/docs/building/tooling/test-runners/interface)
- The docker interface the tester needs to satisfy --> [docker](https://exercism.org/docs/building/tooling/test-runners/docker)

For documentation about the internals of this repo, please see:

- How this works --> [how-this-works.md](https://github.com/exercism/elixir-test-runner/blob/master/how-this-works.md)
