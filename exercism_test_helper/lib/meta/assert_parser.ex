defmodule Meta.AssertParser do
  def parse(assert_string) do
    {:ok, comparator, command, expected} =
      assert_string
      |> Code.string_to_quoted!()
      |> separate_assert()

    command_str = Macro.to_string(command)
    expected_str = expected |> Macro.to_string() |> format_expected()

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

  def expected_to_phrase(:===, expected) do
    "to strict equal #{expected}"
  end

  def expected_to_phrase(:==, expected) do
    "to equal #{expected}"
  end

  def expected_to_phrase(:>=, expected) do
    "to be greater than or equal to #{expected}"
  end

  def expected_to_phrase(:<=, expected) do
    "to be less than or equal to #{expected}"
  end

  def expected_to_phrase(:<, expected) do
    "to be less than #{expected}"
  end

  def expected_to_phrase(:>, expected) do
    "to be greater than #{expected}"
  end

  defp format_expected(str) when is_binary(str) do
    str
    # Commented out for now.
    # |> String.replace_leading(~S'"', "")
    # |> String.replace_trailing(~S'"', "")
  end
end
