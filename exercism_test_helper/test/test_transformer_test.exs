defmodule TestTransformerTest do
  use ExUnit.Case, async: false

  # Testing framework inspired by the JUnit Formatter,
  # located at: https://github.com/victorolinasc/junit-formatter

  import ExUnit.CaptureIO

  defmacrop defsuite(do: block) do
    quote do
      {:module, name, _, _} =
        defmodule unquote(Module.concat(__MODULE__, :"Test#{System.unique_integer([:positive])}")) do
          use ExUnit.Case

          unquote(block |> TestTransformer.transform_test_ast())
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

      output = capture_io(fn -> run() end)

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

      output = capture_io(fn -> run() end)

      assert output == desired
    end
  end

  defp run(opts \\ []) do
    ExUnit.configure(Keyword.merge(opts, formatters: [OutputFormatter]))

    funs = ExUnit.Server.__info__(:functions)

    if Keyword.has_key?(funs, :modules_loaded) do
      ExUnit.Server.modules_loaded()
    end

    ExUnit.run()
  end
end
