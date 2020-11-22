defmodule AssertParserTest do
  use ExUnit.Case, async: false

  alias Meta.AssertParser

  describe "separate_assert" do
    for op <- [:==, :===, :>=, :<=, :<, :>] do
      @op op

      test "#{@op}" do
        assert_ast = "assert 1 #{@op} 2" |> Code.string_to_quoted!()
        assert AssertParser.separate_assert(assert_ast) == {:ok, @op, 1, 2}
      end
    end
  end

  describe "expected_to_phrase" do
    test "==" do
      assert AssertParser.expected_to_phrase(:==, 1) == "to equal 1"
    end

    test "===" do
      assert AssertParser.expected_to_phrase(:===, 1) == "to strict equal 1"
    end

    test ">=" do
      assert AssertParser.expected_to_phrase(:>=, 1) == "to be greater than or equal to 1"
    end

    test "<=" do
      assert AssertParser.expected_to_phrase(:<=, 1) == "to be less than or equal to 1"
    end

    test "<" do
      assert AssertParser.expected_to_phrase(:<, 1) == "to be less than 1"
    end

    test ">" do
      assert AssertParser.expected_to_phrase(:>, 1) == "to be greater than 1"
    end
  end

  describe "parse" do
    test "simple" do
      assert AssertParser.parse("assert 1 == 1") == {:ok, "1", "to equal 1"}
    end

    test "expression" do
      assert AssertParser.parse("assert 1 + 1 <= 2") ==
               {:ok, "1 + 1", "to be less than or equal to 2"}
    end

    test "string" do
      assert AssertParser.parse(~S'assert Function.call() == "Hello"') ==
               {:ok, "Function.call()", ~S'to equal "Hello"'}
    end
  end
end
