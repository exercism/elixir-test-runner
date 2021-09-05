defmodule HelloWorldTest do
  use ExUnit.Case
  @tag task_id: 1
  test "says 'Hello, World!'" do
    assert HelloWorld.hello() == "Hello, World!"
  end

  @tag task_id: 1
  @tag :pending
  test "says 'Bye, World!'" do
    assert HelloWorld.bye() == "Bye, World!"
  end

  describe "test in describe" do
    @tag task_id: 1
    @tag :pending
    test "says 'Hello, World!' in describe" do
      assert HelloWorld.hello() == "Hello, World!"
    end

    @tag task_id: 1
    @tag :pending
    test "says 'Bye, World!' in describe" do
      assert HelloWorld.bye() == "Bye, World!"
    end
  end

  @tag task_id: 2
  @tag :pending
  test "failing test" do
    assert [1, 2, 3] == [2, 3]
  end

  @tag task_id: 3
  @tag :pending
  @tag :slow
  test "Would fail but should not be called from the test runner" do
    assert "tim" == "angelika"
  end
end
