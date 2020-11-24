defmodule ExercismTestHelper.CLI.Command.TestTransform do
  def run([file, output_file]) do
    transformed =
      file
      |> File.read!()
      |> TestSource.Transformer.transform_test()

    File.write!(output_file, transformed)
  end
end
