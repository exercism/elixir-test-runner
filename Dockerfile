FROM hexpm/elixir:1.20.1-erlang-29.0-debian-bookworm-20260610 as builder

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

FROM hexpm/elixir:1.20.1-erlang-29.0-debian-bookworm-20260610 as runner
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /opt/test-runner /opt/test-runner

# Install SSL ca certificates
RUN apt-get update && \
  apt-get install bash jo jq -y

WORKDIR /opt/test-runner

# Consolidate Elixir's protocols once, so that each run only has to
# consolidate the solution's own protocols
RUN bin/build-consolidated.sh /opt/test-runner/consolidated

# Record the modules that every run loads, so that each run can load them in
# the background. This runs the hello-world fixture, so clear /tmp afterwards.
RUN bin/build-preload.sh /opt/test-runner/preload.bin && rm -rf /tmp/*

USER appuser

WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
