defmodule ExercismTestHelper.CLI do
  @moduledoc false

  @usage """
  Usage:
  > exercism_test_helper [--transform <filename> [--replace]]
  > exercism_test_helper [--log-to-json <log filename>]
  > exercism_test_helper [--combine <result json>:<log json>]
  """

  @spec main() :: no_return
  @spec main(list(String.t())) :: no_return
  def main(args \\ []) do
    {argv, _, _} =
      OptionParser.parse(args,
        strict: [
          transform: :string,
          replace: :boolean,
          log_to_json: :string,
          combine: :string
        ]
      )

    cond do
      argv[:transform] ->
        transform_test(argv[:transform], argv[:replace])

      argv[:log_to_json] ->
        log_to_json(argv[:log_to_json])

      argv[:combine] ->
        [result, log] = argv[:combine] |> String.split(":")

        combine(result, log)

      true ->
        IO.puts(@usage)
    end
  end

  def transform_test(file, replace) do
    output_file =
      if replace do
        file
      else
        path = Path.dirname(file)
        name = Path.basename(file, ".exs")
        Path.join(path, name <> "_transformed.exs")
      end

    transformed =
      file
      |> File.read!()
      |> TestTransformer.transform_test()

    File.write!(output_file, transformed)
  end

  def log_to_json(file) do
    json =
      file
      |> File.read!()
      |> String.split("[test started] ", trim: true)
      |> Enum.map(&String.split(&1, "\n", trim: true))
      |> Enum.map(fn [n | os] -> {n, os |> Enum.join("\n")} end)
      |> Enum.into(%{})
      |> Jason.encode!()

    File.write!(file <> ".json", json)
  end

  def combine(result_json_file, log_json_file) do
    results =
      result_json_file
      |> File.read!()
      |> Jason.decode!()

    log =
      log_json_file
      |> File.read!()
      |> Jason.decode!()

    updated =
      results["tests"]
      |> Enum.map(&add_test_output(&1, log))

    updated_results =
      %{results | "tests" => updated}
      |> Jason.encode!()

    File.write!(result_json_file, updated_results)
  end

  defp add_test_output(%{"name" => name} = test, log) do
    cond do
      log[name] ->
        output = log[name]

        output =
          cond do
            String.length(output) > 500 -> String.slice(output, -3..-1) <> "..."
            true -> output
          end

        Map.put(test, "output", output)

      true ->
        test
    end
  end
end
