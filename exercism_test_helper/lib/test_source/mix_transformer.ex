defmodule TestSource.MixTransformer do
  def transform_mix(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> transform_mix_ast()
    |> Macro.to_string()
  end

  def transform_mix_ast(ast) do
    Macro.postwalk(ast, &apply_transforms/1)
  end

  defp apply_transforms({:def, meta, [{:project, _, _} = p, [do: list]]}) do
    {:def, meta, [p, [do: [{:prune_code_paths, false} | list]]]}
  end

  defp apply_transforms(node), do: node
end
