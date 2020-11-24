defmodule ExercismTestHelper.CLI.Command.CombineJSON do
  def run([result_json_file, metadata_json_file, log_json_file]) do
    read_decode = fn filename ->
      filename
      |> File.read!()
      |> Jason.decode!()
    end

    results = read_decode.(result_json_file)
    metadata = read_decode.(metadata_json_file)
    log = read_decode.(log_json_file)

    updated =
      results["tests"]
      |> Enum.map(&add_metadata(&1, metadata))
      |> Enum.map(&add_test_output(&1, log))

    updated_results =
      %{results | "tests" => updated}
      |> Jason.encode!()

    File.write!(result_json_file, updated_results)
  end

  defp add_metadata(%{"name" => name} = test, metadata) do
    cond do
      metadata[name] ->
        entry = metadata[name]

        cond do
          entry["error"] ->
            add_metadata_error_fields(test)

          true ->
            Map.put(test, "expression", entry["expression"])
        end

      true ->
        add_metadata_error_fields(test, "metadata missing for test")
    end
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
        Map.put(test, "output", nil)
    end
  end

  defp add_metadata_error_fields(test, reason \\ "metadata unavailable") do
    test
    |> Map.put("expression", nil)
    |> Map.put("metadata-error", reason)
  end
end
