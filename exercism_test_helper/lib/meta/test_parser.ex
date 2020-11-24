defmodule Meta.TestParser do
  alias Meta.TestParser.{
    Test,
    TestSuite
  }

  def parse(code_string) do
    ast = Code.string_to_quoted!(code_string)

    {_, meta} =
      Macro.traverse(
        ast,
        %TestSuite{},
        &pre_order_parse/2,
        &post_order_parse/2
      )

    meta
  end

  #
  # Functions while traversing down
  #

  def pre_order_parse({:describe, _, [label | _]} = node, acc) do
    {node, %{acc | description: label}}
  end

  def pre_order_parse({:test, _, [name, [do: test_block]]} = node, acc) do
    test = Test.make(acc.description, name, test_block)
    {node, %{acc | tests: acc.tests ++ [test]}}
  end

  def pre_order_parse(node, acc) do
    {node, acc}
  end

  #
  # Functions while traversing up
  #

  def post_order_parse({:describe, _, _} = node, acc) do
    {node, %{acc | description: nil}}
  end

  def post_order_parse(node, acc) do
    {node, acc}
  end

  #
  # Test block parser
  #
end
