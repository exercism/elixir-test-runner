defmodule(HelloWorldTest) do
  use(ExUnit.Case)

  @tag task_id: 1
  test("says 'Hello, World!'") do
    assert(HelloWorld.hello() == "Hello, World!")
  end

  @tag task_id: 2
  test("failing test") do
    assert [1, 2, 3] == [2, 3]
  end
end
