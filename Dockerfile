FROM elixir:1.9.4-alpine as builder

# Install SSL ca certificates
RUN apk update && apk add ca-certificates bash
RUN apk add \
  --no-cache \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
  jo

# Create appuser
RUN adduser -D -g '' appuser

# Get the source code
WORKDIR /opt/test-runner
COPY . .

WORKDIR /opt/test-runner/exercism_formatter
RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get
RUN MIX_ENV=test mix compile
RUN mix test --no-compile

# Build the escript
RUN mix escript.build
RUN mv exercism_formatter ../bin

USER appuser
WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
