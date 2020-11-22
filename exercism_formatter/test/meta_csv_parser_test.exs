defmodule MetaCSVParserTest do
  use ExUnit.Case, async: false

  describe "line_to_entry" do
    test "simple" do
      line = ["testing", "", "1", "assert 1 + 1 == 2"]
      expected = {:ok, %{name: "testing", cmd: "1 + 1", expected: "to equal \"2\""}}
      assert MetaCSVParser.line_to_entry(line) == expected
    end
  end

  describe "parse_stream" do
    test "simple" do
      {:ok, stream} = "\"simple test\",\"\",1,\"assert 1 == 1\"\n" |> StringIO.open()

      assert MetaCSVParser.parse_stream(stream) == [
               {:ok, %{name: "simple test", cmd: "1", expected: ~S'to equal "1"'}}
             ]
    end
  end

  describe "parse_string" do
    test "simple" do
      meta_string = "\"simple test\",\"\",1,\"assert 1 == 1\"\n"

      assert MetaCSVParser.parse_string(meta_string) == [
               {:ok, %{name: "simple test", cmd: "1", expected: ~S'to equal "1"'}}
             ]
    end
  end
end
