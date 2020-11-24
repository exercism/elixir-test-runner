defmodule Meta.StyleTest do
  use ExUnit.Case, async: false

  alias Meta.Style

  test "empty" do
    expr =
      quote do
      end

    assert Style.format(expr) == ""
  end

  test "assert expr" do
    expr =
      quote do
        assert 1
      end

    assert Style.format(expr) == "assert 1"
  end

  test "assert equality expr" do
    expr =
      quote do
        assert 1 == 2
      end

    assert Style.format(expr) == "assert 1 == 2"
  end

  test "if expr" do
    expr =
      quote do
        if true do
          :a
        end
      end

    expected = """
    if true do
      :a
    end
    """

    assert Style.format(expr) == expected
  end

  test "if else expr" do
    expr =
      quote do
        if true do
          :a
        else
          :b
        end
      end

    expected = """
    if true do
      :a
    else
      :b
    end
    """

    assert Style.format(expr) == expected
  end

  test "single block" do
    expr = {:__block__, [], [:a]}
    assert Style.format(expr) == ":a"
  end

  test "double block" do
    expr = {:__block__, [], [:a, :b]}
    assert Style.format(expr) == ":a\n:b"
  end

  test "anonymous 0-arity one-line" do
    expr =
      quote do
        fn -> :a end
      end

    assert Style.format(expr) == "fn -> :a end"
  end

  test "anonymous 1-arity one-line" do
    expr =
      quote do
        fn _x -> :a end
      end

    assert Style.format(expr) == "fn _x -> :a end"
  end

  test "anonymous 2-arity one-line" do
    expr =
      quote do
        fn _x, _y -> :a end
      end

    assert Style.format(expr) == "fn _x, _y -> :a end"
  end

  test "anonymous 1-arity with when one-line" do
    expr =
      quote do
        fn x when is_number(x) -> :a end
      end

    assert Style.format(expr) == "fn x when is_number(x) -> :a end"
  end

  test "anonymous 2-arity with when one-line" do
    expr =
      quote do
        fn x, _y when is_number(x) -> :a end
      end

    assert Style.format(expr) == "fn x, _y when is_number(x) -> :a end"
  end

  test "anonymous 0 arity multi-line" do
    expr =
      quote do
        fn ->
          :a
          :b
        end
      end

    expected = """
    fn ->
      :a
      :b
    end\
    """

    assert Style.format(expr) == expected
  end

  test "anonymous 1 arity multi-line" do
    expr =
      quote do
        fn _x ->
          :a
          :b
        end
      end

    expected = """
    fn _x ->
      :a
      :b
    end\
    """

    assert Style.format(expr) == expected
  end

  test "anonymous 2 arity multi-line" do
    expr =
      quote do
        fn _x, _y ->
          :a
          :b
        end
      end

    expected = """
    fn _x, _y ->
      :a
      :b
    end\
    """

    assert Style.format(expr) == expected
  end

  test "anonymous 2 arity multi-line when when" do
    expr =
      quote do
        fn x, _y when x == 3 ->
          :a
          :b
        end
      end

    expected = """
    fn x, _y when x == 3 ->
      :a
      :b
    end\
    """

    assert Style.format(expr) == expected
  end

  test "anonymous multiclause function" do
    expr =
      quote do
        fn
          x ->
            :a
            :c

          y ->
            :b
        end
      end

    expected = """
    fn
      x ->
        :a
        :c
      y ->
        :b
    end\
    """

    assert Style.format(expr) == expected
  end
end
