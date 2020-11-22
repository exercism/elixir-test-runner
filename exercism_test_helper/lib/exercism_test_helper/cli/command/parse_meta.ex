defmodule ExercismTestHelper.CLI.Command.ParseMeta do
  def run([output_json_filename]) do
    meta = Meta.CSVParser.parse_stream()
    do_run(output_json_filename, meta)
  end

  def run([test_csv_filename, output_json_filename]) do
    {:ok, meta_csv_string} = File.read(test_csv_filename)
    meta = Meta.CSVParser.parse_string(meta_csv_string)
    do_run(output_json_filename, meta)
  end

  defp do_run(output_json_filename, meta) do
    File.write!(output_json_filename, stringify_meta(meta))
  end

  defp stringify_meta(meta) when is_map(meta) do
    {:ok, string} = Jason.encode(meta)
    string
  end
end
