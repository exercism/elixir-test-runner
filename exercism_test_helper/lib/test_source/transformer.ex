defmodule TestSource.Transformer do
  def transform_test(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> transform_test_ast()
    |> Macro.to_string()
  end

  def transform_test_ast(ast) do
    acc = %{describe: nil}

    {ast, _acc} = Macro.traverse(ast, acc, &annotate/2, &apply_transforms/2)
    ast
  end

  defp annotate(node, acc) do
    cond do
      describe?(node) -> {node, %{describe: extract_description(node)}}
      true -> {node, acc}
    end
  end

  defp apply_transforms(node, %{describe: description} = acc) do
    node =
      node
      |> insert_test_io_header(description)
      |> remove_pending_tag()

    cond do
      describe?(node) -> {node, %{describe: nil}}
      true -> {node, acc}
    end
  end

  defp describe?({:describe, _meta, _params}), do: true
  defp describe?(_node), do: false

  defp extract_description({:describe, _meta, [description, _do_tests]}), do: description

  defp insert_test_io_header({:test, meta, [name, block]}, description) do
    name_with_description = if description, do: "#{description} #{name}", else: name

    new_block =
      case block do
        [do: {:__block__, _, b}] ->
          make_test_header_block(b, name_with_description)

        [do: i] ->
          make_test_header_block(List.wrap(i), name_with_description)
      end

    {:test, meta, [name, new_block]}
  end

  defp insert_test_io_header(node, _description), do: node

  defp make_test_header_block(block, name) do
    block = [test_start_header(name) | block]

    [do: {:__block__, [], block}]
  end

  defp test_start_header(name) do
    quote do
      IO.puts("[test started] test " <> unquote(name))
    end
  end

  defp remove_pending_tag({name, meta, args}) when is_list(args),
    do: {name, meta, Enum.reject(args, &pending_tag?/1)}

  defp remove_pending_tag(node), do: node

  defp pending_tag?({:@, _, [{:tag, _, [:pending]}]}), do: true
  defp pending_tag?({:@, _, [{:tag, _, [[pending: _]]}]}), do: true
  defp pending_tag?(_node), do: false
end
