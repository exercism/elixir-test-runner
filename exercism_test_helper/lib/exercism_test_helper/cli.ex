defmodule ExercismTestHelper.CLI do
  @moduledoc false

  alias ExercismTestHelper.CLI.Command.{
    TestTransform,
    OutputLogToJSON,
    CombineJSON,
    ParseMeta
  }

  @usage """
  Usage:
  > exercism_test_helper [--parse-meta-csv <meta csv filename>:<output json filename>]
  > exercism_test_helper [--transform <test filename> [--replace]]
  > exercism_test_helper [--log-to-json <output filename>]
  > exercism_test_helper [--combine <result json>:<metadata json>:<output json>]
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
          combine: :string,
          parse_meta_csv: :string
        ]
      )

    cond do
      argv[:transform] ->
        TestTransform.run(argv[:transform], argv[:replace])

      argv[:log_to_json] ->
        OutputLogToJSON.run(argv[:log_to_json])

      argv[:combine] ->
        [result, metadata, log] = argv[:combine] |> String.split(":")
        CombineJSON.run(result, metadata, log)

      argv[:parse_meta_csv] ->
        argv[:parse_meta_csv] |> String.split(":") |> ParseMeta.run()

      true ->
        IO.puts(@usage)
    end
  end
end
