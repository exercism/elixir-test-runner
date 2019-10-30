defmodule JSONFormatterTest do
  use ExUnit.Case, async: false

  # Testing framework inspired by the JUnit Formatter,
  # located at: https://github.com/victorolinasc/junit-formatter

  defmacrop defsuite(do: block) do
    quote do
      {:module, name, _, _} =
        defmodule unquote(Module.concat(__MODULE__, :"Test#{System.unique_integer([:positive])}")) do
          use ExUnit.Case

          unquote(block)
        end

      name
    end
  end


  describe "testsuite - root" do
    test "tags are present at the root" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      {:ok, json_output} = Jason.decode(output)

      assert_json_path(json_output, ~w{status})
      assert_json_path(json_output, ~w{message})
      assert_json_path(json_output, ~w{tests})
    end
  end

  describe "testsuite - tests key" do
    test "has a list" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      {:ok, json_output} = Jason.decode(output)
      {:ok, tests_value} = json_get_in(json_output, ~w{tests})

      assert tests_value |> is_list()
    end

    test "each element has a name, status, message" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      {:ok, json_output} = Jason.decode(output)

      assert_json_path(json_output, ~w{tests name})
      assert_json_path(json_output, ~w{tests status})
      assert_json_path(json_output, ~w{tests message})
    end

    test "on fail, test status is 'fail'" do
      defsuite do
        test "it will fail", do: assert(false)
      end

      output = run_and_capture_output()

      {:ok, json_output} = Jason.decode(output)
      {:ok, test_status_value} = json_get_in(json_output, ~w{tests status})

      assert test_status_value == "fail"
    end

    test "on pass, test status is 'pass'" do
      defsuite do
        test "will pass", do: assert(true)
      end

      output = run_and_capture_output()

      {:ok, json_output} = Jason.decode(output)
      {:ok, test_status_value} = json_get_in(json_output, ~w{tests status})

      assert test_status_value == "pass"
    end
  end

  defp run_and_capture_output(opts \\ []) do
    ExUnit.configure(Keyword.merge(opts, formatters: [JSONFormatter]))

    funs = ExUnit.Server.__info__(:functions)

    if Keyword.has_key?(funs, :modules_loaded) do
      ExUnit.Server.modules_loaded()
    else
      ExUnit.Server.cases_loaded()
    end

    ExUnit.run()
    File.read!(JSONFormatter.get_report_file_path()) <> "\n"
  end

  defp assert_json_path(json, keys) do
    exists = json_path_exists?(json, keys)

    assert exists, "Path #{keys_to_path(keys)} do not match #{inspect(json)}"
  end

  defp keys_to_path(keys) do
    keys
    |> Enum.map(fn k -> inspect(k) end)
    |> List.insert_at(0, "root")
    |> Enum.join("->")
  end

  defp json_path_exists?(json, keys) do
    case json_get_in(json, keys) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp json_get_in(json, keys) do
    {value, exists} =
      Enum.reduce_while(keys, {json, true}, fn k, {j, _v} ->
        cond do
          is_map(j) && Map.has_key?(j, k) ->
            {:cont, {j[k], true}}

          is_list(j) ->
            first = List.first(j)

            if is_map(first) && Map.has_key?(first, k) do
              {:cont, {first[k], true}}
            else
              {:halt, {j, false}}
            end

          true ->
            {:halt, {j, false}}
        end
      end)

    case exists do
      true -> {:ok, value}
      false -> {:error, "key in path doesn't exist"}
    end
  end
end
