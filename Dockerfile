FROM hexpm/elixir:1.10.4-erlang-23.1.4-ubuntu-focal-20201008

# Install SSL ca certificates
RUN apt-get update && \
  apt-get install curl bash jo -y

# Create appuser
RUN useradd -ms /bin/bash appuser

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
