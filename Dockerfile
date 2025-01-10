FROM hexpm/elixir:1.18.1-erlang-27.2-debian-bookworm-20241223

# Install SSL ca certificates
RUN apt-get update && \
  apt-get install bash jo jq -y

# Create appuser
RUN useradd -ms /bin/bash appuser

# Get the source code
WORKDIR /opt/test-runner
COPY . .

# Compile the formatter
WORKDIR /opt/test-runner/exercism_test_helper
RUN mix local.rebar --force && \
  mix local.hex --force && \
  mix deps.get && \
  MIX_ENV=test mix compile && \
  mix test --no-compile

# Build the escript
RUN MIX_ENV=prod mix escript.build && \
  mv exercism_test_helper /opt/test-runner/bin

# clear temp files created by root to avoid permission issues
RUN rm -rf /tmp/*

USER appuser

WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
