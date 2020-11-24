defmodule Meta.Style do
  def format(ast), do: Macro.to_string(ast, &custom_format/2)

  defp custom_format({func, _, [term, blocks]}, _s) when func in [:if, :unless] do
    formatted_term = Macro.to_string(term, &custom_format/2)
    do_block = Macro.to_string(blocks[:do], &custom_format/2)
    else_block = Macro.to_string(blocks[:else], &custom_format/2)

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

  defp custom_format(_ast, string), do: string
end
