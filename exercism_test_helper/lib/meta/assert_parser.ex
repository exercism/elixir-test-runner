defmodule Meta.AssertParser do
  def parse(assert_string) do
    {:ok, comparator, command, expected} =
      assert_string
      |> Code.string_to_quoted!()
      |> separate_assert()

    expected_str = Macro.to_string(expected)
    command_str = Macro.to_string(command)

    {:ok, command_str, expected_to_phrase(comparator, expected_str)}
  end

  @doc """
  separate_assert
  Takes a function an quoted assert block and returns the command to be evaluated
  to generate the actual value, and the expected value.
  """
  def separate_assert({:assert, _, [{comparator, _, [command, expected]}]})
      when comparator in [:==, :===, :>=, :<=, :<, :>] do
    {:ok, comparator, command, expected}
  end

  @doc """
  Depending on the comparator, facilitate plain language translation
  """
  def expected_to_phrase(comparator, expected_str)

  def expected_to_phrase(:===, expected_str) do
    "to strict equal \"#{expected_str}\""
  end

  def expected_to_phrase(:==, expected_str) do
    "to equal \"#{expected_str}\""
  end

  def expected_to_phrase(:>=, expected_str) do
    "to be greater than or equal to \"#{expected_str}\""
  end

  def expected_to_phrase(:<=, expected_str) do
    "to be less than or equal to \"#{expected_str}\""
  end

  def expected_to_phrase(:<, expected_str) do
    "to be less than \"#{expected_str}\""
  end

  def expected_to_phrase(:>, expected_str) do
    "to be greater than \"#{expected_str}\""
  end
end
