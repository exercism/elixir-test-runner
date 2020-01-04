FROM elixir:1.9.4-alpine as builder

# Install SSL ca certificates
RUN apk update && apk add ca-certificates && apk add bash

# Create appuser
RUN adduser -D -g '' appuser

# Get the source code
WORKDIR /opt/test-runner
COPY . .

WORKDIR exercism_formatter
RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get
RUN MIX_ENV=test mix compile
RUN mix test --no-compile

USER appuser
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
