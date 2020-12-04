defmodule Meta.Style do
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
      end\
      """
    else
      """
      #{func} #{formatted_term} do
        #{do_block}
      end\
      """
    end
  end

  # Custom formatting for block expressions
  defp format({:__block__, _, children}, _) do
    children
    |> Enum.map(fn child -> format(child) end)
    |> Enum.join("\n")
  end

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

  # don't include brackets for the list of functions
  defp format({marker, _, children}, _) when marker in @function_without_parens do
    args = children |> Enum.map(&format/1) |> Enum.join(", ")
    "#{marker} #{args}"
  end

  # Custom formatting for when expression
  defp format({:when, _, children}, _) do
    {params, [clause]} = children |> Enum.split(-1)
    params_str = params |> Enum.map(&format/1) |> Enum.join(", ")
    clause_str = format(clause)
    "#{params_str} when #{clause_str}"
  end

  # Keep default formatting for 0-arity anonymous functions
  defp format({:fn, _, [_]}, formatted) do
    formatted
  end

  # Custom formatting for anonymous functions with more than one clause
  defp format({:fn, _, [_ | _] = block}, _) do
    """
    fn
    #{format_arrows(block)}
    end\
    """
  end

  # Custom formatting for case expression
  defp format({:case, _, [expr, blocks]}, _) do
    expr = format(expr)

    do_block = format_arrows(blocks[:do])

    """
    case #{expr} do
    #{do_block}
    end\
    """
  end

  defp format(_ast, string), do: string

  #
  #
  #
  defp format_arrows(arrows) do
    force_multiline =
      arrows
      |> Enum.any?(fn case_expr ->
        match?({:->, _, [_, {:__block__, _, _}]}, case_expr)
      end)

    arrows
    |> Enum.map(&format_arrow(&1, force_multiline))
    |> Enum.map(&indent_multiline/1)
    |> (fn code_blocks ->
          if force_multiline do
            Enum.join(code_blocks, "\n\n")
          else
            Enum.join(code_blocks, "\n")
          end
        end).()
  end

  #
  # Helper function to format case expressions prettily
  #
  defp format_arrow({:->, _, [[left], right]}, force_multiline) do
    left = format(left)
    right = format(right)

    if force_multiline or String.contains?(right, "\n") do
      """
      #{left} ->
      #{indent_multiline(right)}
      """
    else
      "#{left} -> #{right}"
    end
  end

  #
  # Helper function to indent every line of a multiline string
  # by a specified number of spaces
  #
  defp indent_multiline(string, indentation \\ 2) do
    spaces = String.duplicate(" ", indentation)

    string
    |> String.split("\n", trim: true)
    |> Enum.map(&"#{spaces}#{&1}")
    |> Enum.join("\n")
  end
end
