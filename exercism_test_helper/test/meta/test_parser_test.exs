defmodule Meta.TestParserTest do
  use ExUnit.Case

  alias Meta.TestParser.Test, as: T

  describe "parse/1" do
    test "single test without describe" do
      code = """
      defmodule(HelloWorldTest) do
        use(ExUnit.Case)

        test("says 'Hello, World!'") do
          assert(HelloWorld.hello() == "Hello, World!")
        end
      end
      """

      assert Meta.TestParser.parse(code) == %Meta.TestParser.TestSuite{
               description: nil,
               task_id: nil,
               tests: [
                 %T{
                   name: "test says 'Hello, World!'",
                   task_id: nil,
                   test_code: "assert HelloWorld.hello() == \"Hello, World!\""
                 }
               ]
             }
    end

    test "two tests in a single describe" do
      code = """
      defmodule(HelloWorldTest) do
        use(ExUnit.Case)

        describe "hello" do
          test("says 'Hello, World!'") do
            assert(HelloWorld.hello() == "Hello, World!")
          end

          test("says 'Hello, Alice!'") do
            assert(HelloWorld.hello("Alice") == "Hello, Alice!")
          end
        end
      end
      """

      assert Meta.TestParser.parse(code) == %Meta.TestParser.TestSuite{
               description: nil,
               task_id: nil,
               tests: [
                 %T{
                   name: "test hello says 'Hello, World!'",
                   task_id: nil,
                   test_code: "assert HelloWorld.hello() == \"Hello, World!\""
                 },
                 %T{
                   name: "test hello says 'Hello, Alice!'",
                   task_id: nil,
                   test_code: "assert HelloWorld.hello(\"Alice\") == \"Hello, Alice!\""
                 }
               ]
             }
    end

    test "three tests in two describes" do
      code = """
      defmodule(HelloWorldTest) do
        use(ExUnit.Case)

        describe "hello" do
          test("says 'Hello, World!'") do
            assert(HelloWorld.hello() == "Hello, World!")
          end

          test("says 'Hello, Alice!'") do
            assert(HelloWorld.hello("Alice") == "Hello, Alice!")
          end
        end

        describe "bye" do
          test("says 'Bye :(") do
            assert(HelloWorld.bye() == "Bye :(")
          end
        end
      end
      """

      assert Meta.TestParser.parse(code) == %Meta.TestParser.TestSuite{
               description: nil,
               task_id: nil,
               tests: [
                 %T{
                   name: "test hello says 'Hello, World!'",
                   task_id: nil,
                   test_code: "assert HelloWorld.hello() == \"Hello, World!\""
                 },
                 %T{
                   name: "test hello says 'Hello, Alice!'",
                   task_id: nil,
                   test_code: "assert HelloWorld.hello(\"Alice\") == \"Hello, Alice!\""
                 },
                 %T{
                   name: "test bye says 'Bye :(",
                   task_id: nil,
                   test_code: "assert HelloWorld.bye() == \"Bye :(\""
                 }
               ]
             }
    end

    test "task ids - optional, only apply to a single test" do
      code = """
      defmodule(HelloWorldTest) do
        use(ExUnit.Case)

        @task_id 1
        test("test A1 - task 1") do
        end

        test("test A2 - general") do
        end

        describe "describe1" do
          test("test B1 - general") do
          end

          @task_id 2
          @task_id 1
          test("test B2 - task 1") do
          end

          @task_id 1
          test("test B3 - task 1") do
          end

          @task_id 2
          test("test B4 - task 2") do
          end

          test("test B5 - general") do
          end
        end

        describe "describe2" do
          @task_id 3
          test("test C1 - task 3") do
          end

          test("test C2 - general") do
          end

          @task_id 4
          test("test C3 - task 4") do
          end
        end
      end
      """

      assert Meta.TestParser.parse(code) == %Meta.TestParser.TestSuite{
               description: nil,
               task_id: nil,
               tests: [
                 %T{name: "test test A1 - task 1", task_id: 1, test_code: ""},
                 %T{name: "test test A2 - general", task_id: nil, test_code: ""},
                 %T{name: "test describe1 test B1 - general", task_id: nil, test_code: ""},
                 %T{name: "test describe1 test B2 - task 1", task_id: 1, test_code: ""},
                 %T{name: "test describe1 test B3 - task 1", task_id: 1, test_code: ""},
                 %T{name: "test describe1 test B4 - task 2", task_id: 2, test_code: ""},
                 %T{name: "test describe1 test B5 - general", task_id: nil, test_code: ""},
                 %T{name: "test describe2 test C1 - task 3", task_id: 3, test_code: ""},
                 %T{name: "test describe2 test C2 - general", task_id: nil, test_code: ""},
                 %T{name: "test describe2 test C3 - task 4", task_id: 4, test_code: ""}
               ]
             }
    end
  end
end
