defmodule ExercismTestHelper.CLI.Command.TestTransform do
  def run(file, replace) do
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
      |> TestSource.Transformer.transform_test()

    File.write!(output_file, transformed)
  end
end
