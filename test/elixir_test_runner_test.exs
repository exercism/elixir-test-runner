defmodule ElixirTestRunnerTest do
  use ExUnit.Case

  test "error" do
    assert 3 == 4
  end

  test "success" do
    assert 3 == 3
  end
end
