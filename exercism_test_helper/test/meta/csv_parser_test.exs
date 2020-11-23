defmodule Meta.CSVParserTest do
  use ExUnit.Case, async: false

  alias Meta.CSVParser

  describe "line_to_entry" do
    test "simple" do
      line = ["testing", "", "1", "assert 1 + 1 == 2"]
      expected = {"testing", %{cmd: "1 + 1", expected: "to be equal to 2"}}
      assert CSVParser.line_to_entry(line) == expected
    end

    test "simple refute" do
      line = ["testing", "", "1", "refute 1 + 1 == 3"]
      expected = {"testing", %{cmd: "1 + 1", expected: "to not be equal to 3"}}
      assert CSVParser.line_to_entry(line) == expected
    end
  end

  describe "parse_stream" do
    test "simple" do
      {:ok, stream} = "\"simple test\",\"\",1,\"assert 1 == 1\"\n" |> StringIO.open()

      assert CSVParser.parse_stream(stream) ==
               %{"simple test" => %{cmd: "1", expected: "to be equal to 1"}}
    end
  end

  describe "parse_string" do
    test "simple" do
      meta_string = "\"simple test\",\"\",1,\"assert 1 == 1\"\n"

      assert CSVParser.parse_string(meta_string) ==
               %{"simple test" => %{cmd: "1", expected: "to be equal to 1"}}
    end
  end
end
