defmodule TestSource.Transformer do
  def transform_test(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> transform_test_ast()
    |> Macro.to_string(&fix_get_notation/2)
    |> unescape_final_newlines()
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
      |> escape_newlines()

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

  # this necessary due to a bug in Macro.to_string that is already fixed on Elixir master branch
  # remove when migrating Elixir 1.12 -> 1.13
  defp escape_newlines(string) when is_binary(string),
    do: String.replace(string, "\n", "\\n")

  defp escape_newlines(node), do: node

  # this necessary due to a bug in Macro.to_string that is already fixed on Elixir master branch
  # remove when migrating Elixir 1.12 -> 1.13
  defp unescape_final_newlines(str),
    do: String.replace(str, "\\\\n", "\\n")

  # this necessary due to a bug in Macro.to_string that is already fixed on Elixir master branch
  # remove when migrating Elixir 1.12 -> 1.13
  defp fix_get_notation(node, string) do
    cond do
      # fix palindrome-products were palindromes[97] becomes palindromes'a'
      is_list(node) and Enum.all?(node, &Kernel.is_integer/1) ->
        inspect(node, charlists: :as_lists, limit: :infinity)

      # fix forth where strings in special forms don't get unescaped
      is_binary(node) and String.starts_with?(string, "<<") ->
        String.replace(node, "\\n", "\n") |> inspect()

      true ->
        string
    end
  end
end
