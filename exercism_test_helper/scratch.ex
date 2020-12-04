defmodule ScratchTest do
  use ExUnit.Case, async: false

  describe "first" do
    test "a" do
      2 + 3
      assert 1 + 1 == 2
    end
  end

  describe "second" do
    test "b" do
      assert :a != :b
    end
  end

  test "c" do
    refute nil
  end
end
