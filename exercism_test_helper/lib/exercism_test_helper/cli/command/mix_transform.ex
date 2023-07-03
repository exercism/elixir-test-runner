defmodule ExercismTestHelper.CLI.Command.MixTransform do
  def run([file, output_file]) do
    transformed =
      file
      |> File.read!()
      |> TestSource.MixTransformer.transform_mix()

    File.write!(output_file, transformed)
  end
end
