defmodule ElixirTestRunner.JSONFormatter do
  @moduledoc false
  use GenServer

  import ExUnit.Formatter, only: [format_test_failure: 5]

  # Callbacks

  def init(opts) do
    config = %{
      seed: opts[:seed],
      trace: opts[:trace],
      colors: [enabled: false],
      width: opts[:width] || 80,
      slowest: opts[:slowest],
      test_counter: %{},
      test_timings: [],
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0,

      json_path: opts[:json_path] || false,
      results: %{
        status: :pass, # or :fail, or :error
        message: nil,
        tests: [
          # {
          #   name: "Test tthat the thing works",
          #   status: :fail, # or :pass, or :error
          #   message: "Expected 42 but got 123123"
          # }
        ]
      }
    }

    {:ok, config}
  end

  def handle_cast({:suite_started, _opts}, config) do
    {:noreply, config}
  end

  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    json_results = "{\"errors\":#{Jason.encode!(config.results)}}"

    if config.json_path do
      File.write!(config.json_path, json_results)
    else
      IO.puts(json_results)
    end

    {:noreply, config}
  end

  def handle_cast({:test_started, %ExUnit.Test{} = _test}, config) do
    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: nil} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)
    test_timings = update_test_timings(config.test_timings, test)

    test = %{name: test.name, status: :pass, message: nil}
    results = %{config.results | tests: [test | config.results.tests]}

    config = %{config | test_counter: test_counter, test_timings: test_timings, results: results}

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:excluded, _}} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)

    test = %{name: test.name, status: :fail, message: "test excluded"}
    status = update_result_status(config.results.status, :fail)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{config | test_counter: test_counter, excluded_counter: config.excluded_counter + 1, results: results}

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, _}} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)

    test = %{name: test.name, status: :fail, message: "test skipped"}
    status = update_result_status(config.results.status, :fail)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{config | test_counter: test_counter, skipped_counter: config.skipped_counter + 1, results: results}

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)

    test = %{name: test.name, status: :error, message: "test error"}
    status = update_result_status(config.results.status, :error)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{config | test_counter: test_counter, invalid_counter: config.invalid_counter + 1, results: results}

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, failures}} = test}, config) do
    formatted =
      format_test_failure(
        test,
        failures,
        config.failure_counter + 1,
        config.width,
        &formatter(&1, &2, config)
      )

    test_counter = update_test_counter(config.test_counter, test)
    test_timings = update_test_timings(config.test_timings, test)
    failure_counter = config.failure_counter + 1

    test = %{name: test.name, status: :fail, message: formatted}
    status = update_result_status(config.results.status, :fail)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{
      config
      | test_counter: test_counter,
        test_timings: test_timings,
        failure_counter: failure_counter,
        results: results
    }

    {:noreply, config}
  end

  def handle_cast({:module_started, %ExUnit.TestModule{} = _module}, config) do
    {:noreply, config}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{} = _module}, config) do
    {:noreply, config}
  end

  def handle_cast(:max_failures_reached, config) do
    {:noreply, config}
  end

  def handle_cast(_, config) do
    {:noreply, config}
  end

  # Update Utility Functions

  defp update_test_counter(test_counter, %{tags: %{test_type: test_type}}) do
    Map.update(test_counter, test_type, 1, &(&1 + 1))
  end

  defp update_test_timings(timings, %ExUnit.Test{} = test) do
    [test | timings]
  end

  defp update_result_status(:pass, status), do: status
  defp update_result_status(:fail, status), do: status
  defp update_result_status(:error, _status), do: :error

  # Formatter Utility Functions -- from ExUnit.CLIFormatter

  defp formatter(:diff_enabled?, _, %{colors: colors}), do: colors[:enabled]

  defp formatter(:error_info, msg, config), do: colorize(:red, msg, config)

  defp formatter(:extra_info, msg, config), do: colorize(:cyan, msg, config)

  defp formatter(:location_info, msg, config), do: colorize([:bright, :black], msg, config)

  defp formatter(:diff_delete, msg, config), do: colorize(:red, msg, config)

  defp formatter(:diff_delete_whitespace, msg, config),
    do: colorize(IO.ANSI.color_background(2, 0, 0), msg, config)

  defp formatter(:diff_insert, msg, config), do: colorize(:green, msg, config)

  defp formatter(:diff_insert_whitespace, msg, config),
    do: colorize(IO.ANSI.color_background(0, 2, 0), msg, config)

  defp formatter(:blame_diff, msg, %{colors: colors} = config) do
    if colors[:enabled] do
      colorize(:red, msg, config)
    else
      "-" <> msg <> "-"
    end
  end

  defp formatter(_, msg, _config), do: msg

  # Colorize Utility Functions -- from ExUnit.CLIFormatter

  defp colorize(escape, string, %{colors: colors}) do
    if colors[:enabled] do
      [escape, string, :reset]
      |> IO.ANSI.format_fragment(true)
      |> IO.iodata_to_binary()
    else
      string
    end
  end
end
