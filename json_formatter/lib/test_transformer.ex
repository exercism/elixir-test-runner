defmodule TestTransformer do
  def transform_test(file, _opts \\ []) do
    path = Path.dirname(file)
    name = Path.basename(file, ".exs")

    transformed =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> transform_test_ast()
      |> Macro.to_string()

    File.write!(Path.join(path, (name <> "_transformed.exs")), transformed)
  end

  def transform_test_ast(ast) do
    ast
    |> Macro.prewalk(&apply_transforms/1)
  end

  defp apply_transforms(node) do
    node
    |> insert_test_io_header()
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
end
