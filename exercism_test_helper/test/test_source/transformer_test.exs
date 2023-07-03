defmodule TestSource.TransformerTest do
  use ExUnit.Case, async: false

  # Testing framework inspired by the JUnit Formatter,
  # located at: https://github.com/victorolinasc/junit-formatter

  import ExUnit.CaptureIO

  defmacrop defsuite(do: block) do
    quote do
      {:module, name, _, _} =
        defmodule unquote(Module.concat(__MODULE__, :"Test#{System.unique_integer([:positive])}")) do
          use ExUnit.Case

          unquote(block |> TestSource.Transformer.transform_test_ast())
        end

      name
    end
  end

  describe "testsuite - root" do
    test "test start and finish headers are added" do
      defsuite do
        test "hello world" do
          IO.puts(:stdio, "Hello, World!")

          assert(true)
        end
      end

      desired = """
      [test started] test hello world
      Hello, World!
      """

      output = capture_io(fn -> run(exclude: [:slow, :pending]) end)

      assert output == desired
    end
  end

  describe "testsuite - two tests" do
    test "two are in order" do
      defsuite do
        test "hello world" do
          IO.puts(:stdio, "Hello, World!")

          assert(false)
        end

        @tag :pending
        test "spanish weather" do
          IO.puts(:stdio, "The rain in Spain stays mainly on the plain.")

          assert(false)
        end
      end

      desired = """
      [test started] test hello world
      Hello, World!
      [test started] test spanish weather
      The rain in Spain stays mainly on the plain.
      """

      output = capture_io(fn -> run(exclude: [:slow, :pending]) end)

      assert output == desired
    end
  end

  describe "testsuite - more tests" do
    test "strips pending tags" do
      defsuite do
        test "will be run 1" do
          assert(true)
        end

        @tag :pending
        test "will be run 2" do
          assert(true)
        end

        @tag pending: true
        test "will be run 3" do
          assert(true)
        end

        @tag :pending
        @tag :slow
        test "will not be run 1" do
          assert(true)
        end

        @tag :slow
        test "will not be run 2" do
          assert(true)
        end
      end

      desired = """
      [test started] test will be run 1
      [test started] test will be run 2
      [test started] test will be run 3
      """

      output = capture_io(fn -> run(exclude: [:slow, :pending]) end)

      assert output == desired
    end
  end

  describe "testsuite - tests with describe blocks" do
    test "strips pending tags" do
      defsuite do
        describe "group 1" do
          test "will be run 1" do
            assert(true)
          end

          @tag :pending
          test "will be run 2" do
            assert(true)
          end
        end

        describe "group 2" do
          @tag pending: true
          test "will be run 3" do
            assert(true)
          end
        end

        describe "group 3" do
          @tag :pending
          @tag :slow
          test "will not be run 1" do
            assert(true)
          end

          @tag :slow
          test "will not be run 2" do
            assert(true)
          end
        end
      end

      desired = """
      [test started] test group 1 will be run 1
      [test started] test group 1 will be run 2
      [test started] test group 2 will be run 3
      """

      output = capture_io(fn -> run(exclude: [:slow, :pending]) end)

      assert output == desired
    end
  end

  defp run(opts) do
    ExUnit.configure(Keyword.merge(opts, formatters: [OutputFormatter]))

    funs = ExUnit.Server.__info__(:functions)

    if Keyword.has_key?(funs, :modules_loaded) do
      ExUnit.Server.modules_loaded(false)
    end

    ExUnit.run()
  end
end
