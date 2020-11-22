defmodule ExercismTestHelper.CLI.Command.CombineJSON do
  def run(result_json_file, log_json_file) do
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
