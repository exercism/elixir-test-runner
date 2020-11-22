defmodule Meta.CSVParser do
  @csv_parser_module TestCSVParser

  alias Meta.AssertParser

  defp define_parser() do
    unless Code.ensure_loaded?(@csv_parser_module) do
      NimbleCSV.define(@csv_parser_module, separator: ",", escape: ~S'"')
    end
  end

  def parse_string(meta_string) do
    {:ok, stream} = meta_string |> StringIO.open()
    parse_stream(stream)
  end

  def parse_stream(stream_source \\ :stdio) do
    define_parser()
    stream = IO.stream(stream_source, :line)

    Kernel.apply(@csv_parser_module, :parse_stream, [stream, [skip_headers: false]])
    |> Stream.map(&line_to_entry/1)
    |> Enum.to_list()
  end

  @doc """
  """
  def line_to_entry(line) do
    [test_name, pre_assert_code, assertion_block_count | assertion_code_blocks] = line

    case assertion_block_count do
      count when count != "1" ->
        {:error, "unable to use meta from test cases which have more than one assertion"}

      _ ->
        {:ok, command, expected} = assertion_code_blocks |> hd |> AssertParser.parse()

        command =
          case pre_assert_code do
            "" -> command
            code when is_binary(code) -> code <> "\n" <> command
          end

        {:ok,
         %{
           name: test_name,
           cmd: command,
           expected: expected
         }}
    end
  end
end
