defmodule TestSource.Transformer do
  def transform_test(file_contents) do
    file_contents
    |> Code.string_to_quoted!()
    |> transform_test_ast()
    |> Macro.to_string()
    |> unescape_final_newlines()
  end

  def transform_test_ast(ast) do
    ast
    |> Macro.prewalk(&apply_transforms/1)
  end

  defp apply_transforms(node) do
    node
    |> insert_test_io_header()
    |> remove_pending_tag()
    |> escape_newlines()
  end

  defp insert_test_io_header({:test, meta, [name, block]}) do
    new_block =
      case block do
        [do: {:__block__, _, b}] ->
          make_test_header_block(b, name)

        [do: i] ->
          make_test_header_block(i, name)
      end

    {:test, meta, [name, new_block]}
  end

  defp insert_test_io_header(node), do: node

  defp make_test_header_block(block, name) when not is_list(block) do
    make_test_header_block([block], name)
  end

  defp make_test_header_block(block, name) when is_list(block) do
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
end
