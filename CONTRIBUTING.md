# How to contribute to Exercism's Elixir Test Runner

1. Look at the issues, see if there is a feature that is looking to be implemented of a bug that needs assistance.
2. Suggest a feature or submit a bug report, discuss proposed feature before sinking too much time into it -- the current efforts/features in the works are not always well documented.

## Some ideas for features yet to be implemented

- local testing
  - It would be nice to be able to be able to clone the repo and be able to build and test the docker image more easily against arbitrary elixir submissions.
  This might look like a bash script that calls the relevant docker build and run commands with a solution uuid which then uses locally installed exercism cli application to download the solution to a known location, run it and spit out the testing results.
- dockerfile improvements
  - I'm no docker expert and I wonder if there are optimizations that can be done for the image build process to be able to better utilize cached build steps.
