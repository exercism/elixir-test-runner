defmodule ExercismTestHelper.CLI.Command.CombineJSON do
  @version 3

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
      |> Enum.map(&add_metadata(&1, metadata["tests"]))
      |> Enum.map(&add_test_output(&1, log))

    updated_results =
      results
      |> Map.merge(%{"version" => @version, "tests" => updated})
      |> Jason.encode!()

    File.write!(result_json_file, updated_results)
  end

  defp add_metadata(%{"name" => name} = test, metadata) do
    test_metadata = Enum.find(metadata, nil, fn entry -> entry["name"] == name end)

    cond do
      test_metadata ->
        cond do
          test_metadata["error"] ->
            add_metadata_error_fields(test)

          true ->
            Map.merge(test, Map.take(test_metadata, ["test_code", "task_id"]))
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
            String.length(output) > 500 ->
              output
              |> String.split_at(500 - 3)
              |> elem(0)
              |> Kernel.<>("...")

            true ->
              output
          end

        Map.put(test, "output", output)

      true ->
        Map.put(test, "output", nil)
    end
  end

  defp add_metadata_error_fields(test, reason \\ "metadata unavailable") do
    test
    |> Map.put("test_code", nil)
    |> Map.put("metadata-error", reason)
  end
end
