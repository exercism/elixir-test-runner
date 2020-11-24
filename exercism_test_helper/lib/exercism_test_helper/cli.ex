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
  > exercism_test_helper [--parse-meta-csv <test filename>:<output json filename>]
  > exercism_test_helper [--transform <test filename>:<transformed test filename>]
  > exercism_test_helper [--log-to-json <output filename>:<output json filename>]
  > exercism_test_helper [--combine <result json>:<metadata json>:<output json>]
  """

  @spec main() :: no_return
  @spec main(list(String.t())) :: no_return
  def main(args \\ []) do
    {argv, _, _} =
      OptionParser.parse(args,
        strict: [
          transform: :string,
          log_to_json: :string,
          combine: :string,
          parse_meta_csv: :string
        ]
      )

    cond do
      argv[:transform] ->
        argv[:transform]
        |> String.split(":")
        |> TestTransform.run()

      argv[:log_to_json] ->
        argv[:log_to_json]
        |> String.split(":")
        |> OutputLogToJSON.run()

      argv[:combine] ->
        argv[:combine]
        |> String.split(":")
        |> CombineJSON.run()

      argv[:parse_meta_csv] ->
        argv[:parse_meta_csv]
        |> String.split(":")
        |> ParseMeta.run()

      true ->
        IO.puts(@usage)
    end
  end
end
