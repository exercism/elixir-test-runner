defmodule ExercismFormatter.CLI do
  @moduledoc false

  @usage """
    Usage:
    > exercism_formatter [--transform <filename> [--replace]]
    """

  @spec main() :: no_return
  @spec main(list(String.t())) :: no_return
  def main(args \\ []) do
    {argv, _, _} =
      OptionParser.parse(args, strict: [
        transform: :string,
        replace: false
      ])

    cond do
      argv[:transform] ->
        transform_test(argv)

      true ->
        IO.puts(@usage)
    end
  end

  def transform_test(argv) do
    file = argv[:transform]

    output_file =
      if argv[:replace] do
        file
      else
        path = Path.dirname(file)
        name = Path.basename(file, ".exs")
        Path.join(path, (name <> "_transformed.exs"))
      end

    transformed =
      file
      |> File.read!()
      |> TestTransformer.transform_test()

    File.write!(output_file, transformed)
  end
end
