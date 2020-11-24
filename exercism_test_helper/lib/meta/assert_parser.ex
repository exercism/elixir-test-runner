defmodule Meta.AssertParser do
  def parse(assert_string) do
    assert_string
    |> Code.string_to_quoted!()
    |> parse_ast()
  end

  def parse_ast(assert_ast) do
    {:ok, assertion, comparator, command, expected} = separate_assertion(assert_ast)

    command_str = Macro.to_string(command)
    expected_str = expected |> Macro.to_string() |> format_expected()

    {:ok, command_str, expected_to_phrase(assertion, comparator, expected_str)}
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

  @doc """
  Depending on the assertion and comparator, facilitate plain language translation
  """
  def expected_to_phrase(assertion, comparator, expected_str)

  # phrases for assert
  def expected_to_phrase(:assert, :===, expected) do
    "to be strictly equal to #{expected}"
  end

  def expected_to_phrase(:assert, :==, expected) do
    "to be equal to #{expected}"
  end

  def expected_to_phrase(:assert, :!==, expected) do
    "to not be strictly equal to #{expected}"
  end

  def expected_to_phrase(:assert, :!=, expected) do
    "to not be equal to #{expected}"
  end

  def expected_to_phrase(:assert, :>=, expected) do
    "to be greater than or equal to #{expected}"
  end

  def expected_to_phrase(:assert, :<=, expected) do
    "to be less than or equal to #{expected}"
  end

  def expected_to_phrase(:assert, :<, expected) do
    "to be less than #{expected}"
  end

  def expected_to_phrase(:assert, :>, expected) do
    "to be greater than #{expected}"
  end

  # phrases for refute
  def expected_to_phrase(:refute, :===, expected) do
    "to not be strictly equal to #{expected}"
  end

  def expected_to_phrase(:refute, :==, expected) do
    "to not be equal to #{expected}"
  end

  def expected_to_phrase(:refute, :!==, expected) do
    "to be strictly equal to #{expected}"
  end

  def expected_to_phrase(:refute, :!=, expected) do
    "to be equal to #{expected}"
  end

  def expected_to_phrase(:refute, :>=, expected) do
    "to not be greater than or equal to #{expected}"
  end

  def expected_to_phrase(:refute, :<=, expected) do
    "to not be less than or equal to #{expected}"
  end

  def expected_to_phrase(:refute, :<, expected) do
    "to not be less than #{expected}"
  end

  def expected_to_phrase(:refute, :>, expected) do
    "to not be greater than #{expected}"
  end

  @doc false
  defp format_expected(str) do
    str
    # Commented out for now.
    # |> String.replace_leading(~S'"', "")
    # |> String.replace_trailing(~S'"', "")
  end
end
