defmodule ExercismTestHelper.Preload do
  @moduledoc """
  Loads the modules that every run needs in a background process.

  A test run loads over 200 modules (the Elixir compiler, ExUnit, Logger,
  Jason and this helper). If the runner loads each one when it first calls it,
  that loading is a large part of a short run. `bin/run.sh` calls `start/0`
  with `erl -s` as soon as the VM boots. It starts a process that loads the
  modules on a list, while the runner gets on with its first steps on the
  other CPU. When the runner needs a module, it has usually been loaded already.

  The list is built once, when the Docker image is built.
  `bin/build-preload.sh` runs the hello-world fixture with
  `EXERCISM_RECORD_PRELOAD` set to the path of the list. The runner calls
  `record/1` after each of its steps, and `save/0` at the end.
  """

  @record_env "EXERCISM_RECORD_PRELOAD"

  # The batches are small, so that the runner can use the first modules
  # while the rest are still loading.
  @batch_size 25

  @doc """
  Loads the modules listed in the file named by `EXERCISM_PRELOAD`, in a
  background process.

  This runs before Elixir has started, so it only calls Erlang functions.
  """
  def start do
    case :os.getenv(~c"EXERCISM_PRELOAD") do
      false ->
        :ok

      path ->
        spawn(fn ->
          with {:ok, binary} <- :file.read_file(path) do
            for batch <- :erlang.binary_to_term(binary) do
              :code.ensure_modules_loaded(batch)
            end
          end
        end)

        :ok
    end
  end

  @doc """
  Records the modules loaded since the previous step, if
  `EXERCISM_RECORD_PRELOAD` is set. Otherwise it does nothing.
  """
  def record(step) do
    if System.get_env(@record_env) do
      steps = Process.get(__MODULE__, [])
      seen = steps |> Enum.flat_map(&elem(&1, 1)) |> MapSet.new()
      new = for {module, _file} <- :code.all_loaded(), module not in seen, do: module

      Process.put(__MODULE__, steps ++ [{step, new}])
    end

    :ok
  end

  @doc """
  Writes the recorded modules to the file named by `EXERCISM_RECORD_PRELOAD`,
  as batches in the order the runner first needed them.

  The list only keeps modules from Erlang, Elixir and this helper's build.
  It leaves out the solution and its tests. It also leaves out protocols,
  because the runner must load those in their consolidated form.
  """
  def save do
    if path = System.get_env(@record_env) do
      roots = preload_roots()

      batches =
        for {_step, modules} <- Process.get(__MODULE__, []),
            batch = Enum.filter(modules, &preload?(&1, roots)),
            batch != [],
            chunk <- Enum.chunk_every(batch, @batch_size),
            do: chunk

      File.write!(path, :erlang.term_to_binary(batches))
    end

    :ok
  end

  defp preload?(module, roots) do
    file = :code.which(module)

    is_list(file) and
      Enum.any?(roots, &String.starts_with?(to_string(file), &1)) and
      not function_exported?(module, :__protocol__, 1)
  end

  # The Erlang install, Elixir's lib directory, and the helper's
  # _build/test/lib directory (which also holds Jason).
  defp preload_roots do
    elixir_lib = :code.lib_dir(:elixir) |> to_string() |> Path.dirname()

    helper_lib =
      :code.which(__MODULE__)
      |> to_string()
      |> Path.dirname()
      |> Path.dirname()
      |> Path.dirname()

    Enum.map([to_string(:code.root_dir()), elixir_lib, helper_lib], &(&1 <> "/"))
  end
end
