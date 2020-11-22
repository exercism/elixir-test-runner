defmodule ExercismTestHelper.CLI do
  @moduledoc false

  alias ExercismTestHelper.CLI.Command.{TestTransform, OutputLogToJSON, CombineJSON}

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
        TestTransform.run(argv[:transform], argv[:replace])

      argv[:log_to_json] ->
        OutputLogToJSON.run(argv[:log_to_json])

      argv[:combine] ->
        [result, log] = argv[:combine] |> String.split(":")
        CombineJSON.run(result, log)

      true ->
        IO.puts(@usage)
    end
  end
end
