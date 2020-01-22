# ElixirTestRunner

![](https://github.com/exercism/elixir-test-runner/workflows/Elixir%20CI/badge.svg)

Exercism Automated Test Runner for Elixir Exercises

## Environment

The test runner currently targets exercises supporting Elixir >= 1.6 and Erlang/OTP >= 20, but is running on Elixir 1.9.4 on the `elixir:1.9.4-alpine` docker image.

The `Dockerfile` also has added `bash` and `jo` to the image (though `jo` has been added from the `edge` repository as it has not been added to a main release as of the latest dockerfile push).

## Testing

---

> It is recommended to test BEFORE submitting a PR.  It will test your submission, ensure
> that the repository builds as a whole, and help guard against unintentional, unrelated changes.

---

## Contributing Guide

For an in-depth discussion of how exercism language tracks and exercises work, please see [CONTRIBUTING.md](https://github.com/exercism/elixir-test-runner/blob/master/CONTRIBUTING.md)

## Documentation "How does this thing work?"

For a -- hopefully -- in-depth discussion of how this repo fits inside of the larger automated testing framework, see [exercism's automated testing repo](https://github.com/exercism/automated-tests)

- The interface the tester needs to satisfy --> [interface.md](https://github.com/exercism/automated-tests/blob/master/docs/interface.md)
- The docker interface the tester needs to satisfy --> [docker.md](https://github.com/exercism/automated-tests/blob/master/docs/docker.md)

For documentation about the internals of this repo, please see:

- How this works --> [how-this-works.md](https://github.com/exercism/elixir-test-runner/blob/master/how-this-works.md)
