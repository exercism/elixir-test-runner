defmodule Meta.TestParser.Test do
  @derive {Jason.Encoder, only: [:name, :test_code]}
  defstruct [:name, :test_code]

  alias Meta.TestParser.CodeBlock

  def make(description, name, test_block) do
    test_code = CodeBlock.determine(test_block) |> to_string()

    %__MODULE__{
      name: make_name(description, name),
      test_code: test_code
    }
  end

  defp make_name(nil, name), do: "test #{name}"
  defp make_name(description, name), do: "test #{description} #{name}"
end
