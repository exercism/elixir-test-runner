defmodule Meta.AssertParser.Term do
  @enforce_keys [:type, :value]
  defstruct [:type, :value]

  @type term_t :: :ast | :non_ast | :binary
  @type t :: %__MODULE__{type: term_t(), value: any()}

  defimpl String.Chars do
    def to_string(term) do
      case term.type do
        :ast ->
          Meta.Style.format(term.value)

        :non_ast ->
          inspect(term.value)

        :binary ->
          term.value
      end
    end
  end

  defguardp is_marker(x) when is_atom(x) or is_tuple(x)
  defguardp is_meta(x) when is_list(x)
  defguardp is_children(x) when is_atom(x) or is_list(x)

  defguardp is_ast(x)
            when is_tuple(x) and
                   elem(x, 0) |> is_marker() and
                   elem(x, 1) |> is_meta() and
                   elem(x, 2) |> is_children()

  def determine(value) when is_ast(value) do
    %__MODULE__{
      type: :ast,
      value: value
    }
  end

  def determine({atom, value} = pair) when is_atom(atom) and is_ast(value) do
    %__MODULE__{
      type: :ast,
      value: pair
    }
  end

  def determine(value) when is_binary(value) do
    %__MODULE__{
      type: :binary,
      value: value
    }
  end

  def determine(value) do
    %__MODULE__{
      type: :non_ast,
      value: value
    }
  end
end
