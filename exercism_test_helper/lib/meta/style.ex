defmodule Meta.Style do
  def format(ast) do
    ast
    |> Macro.to_string()
    |> Code.format_string!([line_length: 120, force_do_end_blocks: true])
    |> IO.iodata_to_binary()
  end
end
