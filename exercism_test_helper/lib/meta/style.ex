defmodule Meta.Style do
  @function_without_parens [
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

  def format(ast), do: Macro.to_string(ast, &format/2)

  # Custom formatting handler for `if` and `unless` expressions
  defp format({func, _, [term, blocks]}, _) when func in [:if, :unless] do
    formatted_term = format(term)
    do_block = format(blocks[:do])
    else_block = format(blocks[:else])

    if Keyword.has_key?(blocks, :else) do
      """
      #{func} #{formatted_term} do
        #{do_block}
      else
        #{else_block}
      end
      """
    else
      """
      #{func} #{formatted_term} do
        #{do_block}
      end
      """
    end
  end

  defp format({:__block__, _, children}, _) do
    children
    |> Enum.map(fn child -> format(child) end)
    |> Enum.join("\n")
  end

  defp format({marker, _, children}, _) when marker in @function_without_parens do
    args = children |> Enum.map(&format/1) |> Enum.join(", ")
    "#{marker} #{args}"
  end

  defp format({:when, _, children}, _) do
    {params, [clause]} = children |> Enum.split(-1)
    params_str = params |> Enum.map(&format/1) |> Enum.join(", ")
    clause_str = format(clause)
    "#{params_str} when #{clause_str}"
  end

  defp format(_ast, string), do: string
end
