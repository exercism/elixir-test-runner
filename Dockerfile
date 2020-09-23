FROM elixir:1.10-alpine

# Install SSL ca certificates
RUN apk update && \
  apk add ca-certificates && \
  apk add curl && \
  apk add bash

# Create appuser
RUN adduser -D -g '' appuser

# Install `jo` from the edge repository
# `jo` is not avalable in the standard branch, so it requires an overlay
# TODO: When `jo` is available in the main branch, consider removing this overlay
RUN apk add \
  --no-cache \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
  jo

# Get exercism's tooling_webserver
RUN curl -L -o /usr/local/bin/tooling_webserver \
  https://github.com/exercism/tooling-webserver/releases/download/0.10.0/tooling_webserver && \
  chmod +x /usr/local/bin/tooling_webserver

# Get the source code
WORKDIR /opt/test-runner
COPY . .

# Compile the formatter
WORKDIR /opt/test-runner/exercism_formatter
RUN mix local.rebar --force
RUN mix local.hex --force
RUN mix deps.get
RUN MIX_ENV=test mix compile
RUN mix test --no-compile

# Build the escript
RUN mix escript.build
RUN mv exercism_formatter /opt/test-runner/bin

USER appuser

WORKDIR /opt/test-runner
ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
