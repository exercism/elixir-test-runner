defmodule Meta.AssertParser do
  def parse(assert_string) do
    assert_string
    |> Code.string_to_quoted!()
    |> parse_ast()
  end

  def parse_ast(assert_ast) do
    {:ok, assertion, comparator, command, expected} =
      assert_ast
      |> separate_assertion()

    command_str = Macro.to_string(command)

    {:ok, command_str, expected_to_phrase(assertion, comparator, expected)}
  end

  @doc """
  separate_assertion
  Takes a function an quoted assert block and returns the command to be evaluated
  to generate the actual value, and the expected value.
  """
  @assertions [:assert, :refute]
  @comparators [:==, :===, :>=, :<=, :<, :>, :!=, :!==]
  def separate_assertion({assertion, _, [{comparator, _, [command, expected]}]})
      when assertion in @assertions and comparator in @comparators do
    {:ok, assertion, comparator, command, expected}
  end

  def separate_assertion({assertion, _, [command]}) when assertion in @assertions do
    {:ok, assertion, nil, command, nil}
  end

  @doc """
  Depending on the assertion and comparator, facilitate plain language translation
  """
  def expected_to_phrase(assertion, comparator, expected) do
    case expected do
      str when is_binary(str) ->
        to_phrase(assertion, comparator, "\"#{str}\"")

      _ ->
        to_phrase(assertion, comparator, expected)
    end
  end

  # phrases for assert
  defp to_phrase(:assert, :===, expected) do
    "to be strictly equal to #{expected}"
  end

  defp to_phrase(:assert, :==, expected) do
    "to be equal to #{expected}"
  end

  defp to_phrase(:assert, :!==, expected) do
    "to not be strictly equal to #{expected}"
  end

  defp to_phrase(:assert, :!=, expected) do
    "to not be equal to #{expected}"
  end

  defp to_phrase(:assert, :>=, expected) do
    "to be greater than or equal to #{expected}"
  end

  defp to_phrase(:assert, :<=, expected) do
    "to be less than or equal to #{expected}"
  end

  defp to_phrase(:assert, :<, expected) do
    "to be less than #{expected}"
  end

  defp to_phrase(:assert, :>, expected) do
    "to be greater than #{expected}"
  end

  defp to_phrase(:assert, nil, nil) do
    "to be truthy (not false or nil)"
  end

  # phrases for refute
  defp to_phrase(:refute, :===, expected) do
    "to not be strictly equal to #{expected}"
  end

  defp to_phrase(:refute, :==, expected) do
    "to not be equal to #{expected}"
  end

  defp to_phrase(:refute, :!==, expected) do
    "to be strictly equal to #{expected}"
  end

  defp to_phrase(:refute, :!=, expected) do
    "to be equal to #{expected}"
  end

  defp to_phrase(:refute, :>=, expected) do
    "to not be greater than or equal to #{expected}"
  end

  defp to_phrase(:refute, :<=, expected) do
    "to not be less than or equal to #{expected}"
  end

  defp to_phrase(:refute, :<, expected) do
    "to not be less than #{expected}"
  end

  defp to_phrase(:refute, :>, expected) do
    "to not be greater than #{expected}"
  end

  defp to_phrase(:refute, nil, nil) do
    "to be falsey (false or nil)"
  end
end
