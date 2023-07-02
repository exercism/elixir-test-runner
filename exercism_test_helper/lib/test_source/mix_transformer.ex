defmodule TestSource.MixTransformer do
  @moduledoc """
  This module transforms the provided test's mixfile to disable
  code path pruning. If not disabled, the JSONFormatter module
  will fail to be injected into the test and not produce
  results.
  """
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
