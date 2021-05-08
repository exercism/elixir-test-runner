defmodule(HelloWorldTest) do
  use(ExUnit.Case)

  @task_id 1
  test("says 'Hello, World!'") do
    assert(HelloWorld.hello() == "Hello, World!")
  end
end
