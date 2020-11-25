defmodule Meta.TestParser.Test do
  @derive {Jason.Encoder, only: [:name, :test_body]}
  defstruct [:name, :preamble, :assertions, :command, :expected, :test_body]

  def make(description, name, test_block) do
    test_body = Meta.AssertParser.Term.determine(test_block) |> to_string()
    # {preamble, assertions} = parse_test_block(test_block)
    # {last_command, expected} = parse_assertion(assertions)
    # command = combine_preamble(preamble, last_command)

    %__MODULE__{
      name: make_name(description, name),
      # preamble: preamble,
      # assertions: assertions,
      # command: command,
      # expected: expected,
      test_body: test_body
    }
  end

  defp make_name(nil, name), do: "test #{name}"
  defp make_name(description, name), do: "test #{description} #{name}"

  def parse_test_block(code_block) when not is_list(code_block) do
    parse_test_block([code_block])
  end

  def parse_test_block([{:__block__, _, block}]) do
    parse_test_block(block)
  end

  def parse_test_block(code_block) do
    {preamble, assertions} = Enum.split_with(code_block, &gather_assertions/1)

    case preamble do
      [_ | _] ->
        {preamble, assertions}

      _ ->
        {nil, assertions}
    end
  end

  @assertions [
    :assert,
    :assert_in_delta,
    :assert_raise,
    :assert_receive,
    :assert_received,
    :catch_error,
    :catch_exit,
    :catch_throw,
    :flunk,
    :refute,
    :refute_in_delta,
    :refute_receive,
    :refute_received
  ]
  def gather_assertions({function, _, _}) when function in @assertions, do: false

  def gather_assertions(_), do: true

  @doc false
  def parse_assertion([assertion]) do
    {:ok, command, expected} = Meta.AssertParser.parse_ast(assertion)
    {command, expected}
  end

  def parse_assertion(_assertions), do: {nil, nil}

  @doc false
  def combine_preamble(nil, last_command), do: last_command

  def combine_preamble(preamble, "") do
    preamble_block = {:__block__, [], preamble}
    "#{preamble_block |> Meta.Style.format()}"
  end

  def combine_preamble(preamble, last_command) do
    preamble_block = {:__block__, [], preamble}

    """
    #{preamble_block |> Meta.Style.format()}
    #{last_command}
    """
  end
end
