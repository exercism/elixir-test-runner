defmodule AssertParserTest do
  use ExUnit.Case, async: false

  alias Meta.AssertParser
  alias Meta.AssertParser.Term

  describe "separate_assertion" do
    for op <- [:==, :===, :>=, :<=, :<, :>, :!=, :!==] do
      @op op

      test "#{@op} assert" do
        assert_ast = "assert 1 #{@op} 2" |> Code.string_to_quoted!()

        assert AssertParser.separate_assertion(assert_ast) ==
                 {:ok, :assert, @op, %Term{type: :non_ast, value: 1},
                  %Term{type: :non_ast, value: 2}}
      end

      test "#{@op} refute" do
        assert_ast = "refute 1 #{@op} 3" |> Code.string_to_quoted!()

        assert AssertParser.separate_assertion(assert_ast) ==
                 {:ok, :refute, @op, %Term{type: :non_ast, value: 1},
                  %Term{type: :non_ast, value: 3}}
      end
    end

    test "assert truthy" do
      assert_ast = "assert 1" |> Code.string_to_quoted!()

      assert AssertParser.separate_assertion(assert_ast) ==
               {:ok, :assert, nil, %Term{type: :non_ast, value: 1}, nil}
    end

    test "refute truthy" do
      assert_ast = "refute 1" |> Code.string_to_quoted!()

      assert AssertParser.separate_assertion(assert_ast) ==
               {:ok, :refute, nil, %Term{type: :non_ast, value: 1}, nil}
    end
  end

  describe "expected_to_phrase" do
    test "==" do
      assert AssertParser.expected_to_phrase(:assert, :==, %Term{type: :non_ast, value: 1}) ==
               "to be equal to 1"
    end

    test "===" do
      assert AssertParser.expected_to_phrase(:assert, :===, %Term{type: :non_ast, value: 1}) ==
               "to be strictly equal to 1"
    end

    test ">=" do
      assert AssertParser.expected_to_phrase(:assert, :>=, %Term{type: :non_ast, value: 1}) ==
               "to be greater than or equal to 1"
    end

    test "<=" do
      assert AssertParser.expected_to_phrase(:assert, :<=, %Term{type: :non_ast, value: 1}) ==
               "to be less than or equal to 1"
    end

    test "<" do
      assert AssertParser.expected_to_phrase(:assert, :<, %Term{type: :non_ast, value: 1}) ==
               "to be less than 1"
    end

    test ">" do
      assert AssertParser.expected_to_phrase(:assert, :>, %Term{type: :non_ast, value: 1}) ==
               "to be greater than 1"
    end

    test "!=" do
      assert AssertParser.expected_to_phrase(:assert, :!=, %Term{type: :non_ast, value: 1}) ==
               "to not be equal to 1"
    end

    test "!==" do
      assert AssertParser.expected_to_phrase(:assert, :!==, %Term{type: :non_ast, value: 1}) ==
               "to not be strictly equal to 1"
    end

    test "truthy" do
      assert AssertParser.expected_to_phrase(:assert, nil, nil) ==
               "to be truthy (not false or nil)"
    end
  end

  describe "parse" do
    test "simple" do
      assert AssertParser.parse("assert 1 == 1") == {:ok, "1", "to be equal to 1"}
    end

    test "expression" do
      assert AssertParser.parse("assert 1 + 1 <= 2") ==
               {:ok, "1 + 1", "to be less than or equal to 2"}
    end

    test "string" do
      assert AssertParser.parse(~S'assert Function.call() == "Hello"') ==
               {:ok, "Function.call()", ~S'to be equal to "Hello"'}
    end
  end
end
