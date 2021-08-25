defmodule Meta.TestParser.Test do
  @derive {Jason.Encoder, only: [:name, :test_code, :task_id]}
  defstruct [:name, :test_code, :task_id]

  alias Meta.TestParser.CodeBlock

  def make(description, name, task_id, test_block) do
    test_code = CodeBlock.determine(test_block) |> to_string()

    %__MODULE__{
      name: make_name(description, name),
      task_id: task_id,
      test_code: test_code
    }
  end

  defp make_name(nil, name), do: "test #{name}"
  defp make_name(description, name), do: "test #{description} #{name}"
end
