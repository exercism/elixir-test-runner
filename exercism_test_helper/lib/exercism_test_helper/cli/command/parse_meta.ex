defmodule ExercismTestHelper.CLI.Command.ParseMeta do
  def run([test_filename, output_json_filename]) do
    with {:ok, test_string} <- File.read(test_filename),
         {:test_suite, meta} <- {:test_suite, Meta.TestParser.parse(test_string)},
         {:ok, meta_json_string} <- Jason.encode(meta) do
      File.write!(output_json_filename, meta_json_string)
    end
  end
end
