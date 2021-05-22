defmodule JSONFormatter do
  @moduledoc """
  Module containing the ExUnit formatter for outputting test results in in the desired
  JSON format required by the exercism automated test runner.

  Output configuration inspired by the JUnit Formatter, found at:
  https://github.com/victorolinasc/junit-formatter
  """

  use GenServer

  # Import `format_test_failure/5` to provide useful feedback to submissions
  import ExUnit.Formatter, only: [format_test_failure: 5]

  # Callbacks

  @impl true
  def init(opts) do
    config = %{
      seed: opts[:seed],
      trace: opts[:trace],
      colors: [enabled: true],
      width: opts[:width] || 80,
      slowest: opts[:slowest],
      test_counter: %{},
      test_timings: [],
      failure_counter: 0,
      skipped_counter: 0,
      excluded_counter: 0,
      invalid_counter: 0,
      results: %{
        version: 2,
        # or :fail, or :error
        status: :pass,
        message: nil,
        tests: [
          # {
          #   name: "Test that the thing works",
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

  @impl true
  def handle_cast({:suite_finished, _run_us, _load_us}, config) do
    # tests needs to be reported from first to last
    config = update_in(config, [:results, :tests], &Enum.reverse/1)
    {:ok, json_results} = Jason.encode(config.results)

    file_name = get_report_file_path()

    :ok = File.write(file_name, json_results)

    if System.get_env("JSON_PRINT_FILE") do
      IO.puts(:stderr, "Wrote JSON report to: #{file_name}")
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

    config = %{
      config
      | test_counter: test_counter,
        excluded_counter: config.excluded_counter + 1,
        results: results
    }

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:skipped, _}} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)

    test = %{name: test.name, status: :fail, message: "test skipped"}
    status = update_result_status(config.results.status, :fail)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{
      config
      | test_counter: test_counter,
        skipped_counter: config.skipped_counter + 1,
        results: results
    }

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{state: {:invalid, _}} = test}, config) do
    test_counter = update_test_counter(config.test_counter, test)

    test = %{name: test.name, status: :error, message: "test error"}
    status = update_result_status(config.results.status, :error)
    results = %{config.results | status: status, tests: [test | config.results.tests]}

    config = %{
      config
      | test_counter: test_counter,
        invalid_counter: config.invalid_counter + 1,
        results: results
    }

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

  # Formatter Utility Functions -- from ExUnit.CLIFormatter, but can't import d/t defp in source

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

  # Colorize Utility Functions -- from ExUnit.CLIFormatter, but can't import d/t being private in source

  defp colorize(escape, string, %{colors: colors}) do
    if colors[:enabled] do
      [escape, string, :reset]
      |> IO.ANSI.format_fragment(true)
      |> IO.iodata_to_binary()
    else
      string
    end
  end

  @doc """
  Helper function to get the full path of the generated report file.
  It can be passed 2 configurations via environment variable
  - report_dir: full path of a directory (defaults to `Mix.Project.app_path()`)
  - report_file: name of the generated file (defaults to "results.json")
  """
  @spec get_report_file_path() :: String.t()
  def get_report_file_path do
    prepend = System.get_env("JSON_PREPEND_PROJECT_NAME")

    report_file = System.get_env("JSON_REPORT_FILE", "results.json")
    report_dir = System.get_env("JSON_REPORT_DIR", Mix.Project.app_path())
    prefix = if prepend, do: "#{Mix.Project.config()[:app]}-", else: ""

    Path.join(report_dir, prefix <> report_file)
  end
end
