defmodule ExercismTestHelper.Runner do
  @moduledoc """
  Compiles a solution and runs its tests in a single BEAM, without Mix.

  Before this runner, each test run started seven BEAMs: five calls to the
  escript, then `mix compile`, then `mix test`. Each BEAM has to boot and load
  Elixir, and Mix has to load and check the project, so most of a run went on
  startup. This runner does the same work in one BEAM:

    1. It checks that the project has the shape used by the track's exercises.
    2. It parses the test metadata and rewrites the test file in a second
       process, while it compiles `lib/` with `Kernel.ParallelCompiler`.
    3. It writes the `.app` file, consolidates protocols and starts the
       application, as `mix compile` would.
    4. It runs ExUnit with the options set by `mix test --seed 0 --exclude slow
       --formatter JSONFormatter`.
    5. It builds `results.json` with the same code the escript uses.

  `bin/run.sh` copies the solution to a temporary directory, changes into it,
  and starts this module with the VM's stdout redirected to the `output` file.
  It then looks at the exit code:

    * 0 means the run finished. `results.json` has been written, unless the
      test file failed to compile (`mix test` writes no results then either).
    * 100 means the project isn't one this runner supports. `bin/run.sh` will
      run the tests with Mix instead (`bin/run-with-mix.sh`).
    * 101 means the solution failed to compile. `bin/run.sh` will run
      `mix compile`, so that the student sees Mix's own error message.

  Any other exit code (for example after a crash) also makes `bin/run.sh`
  fall back to Mix.
  """

  alias ExercismTestHelper.CLI.Command.{CombineJSON, OutputLogToJSON}
  alias ExercismTestHelper.Preload

  @use_mix 100
  @compile_error 101

  # The modules of this helper and of Jason. If a solution defined one of
  # them, it would clash with the runner, so it goes to Mix instead.
  @helper_prefixes [
    "Elixir.ExercismTestHelper",
    "Elixir.Meta.",
    "Elixir.TestSource.",
    "Elixir.JSONFormatter",
    "Elixir.Jason"
  ]

  @doc """
  Starts Elixir and Logger, as `elixir:start_cli/0` does, then runs the tests
  and halts the VM with the exit code.

  `bin/run.sh` calls this with `erl -s`. Calling it directly skips the
  `elixir` shell script and the Elixir CLI's argument handling, which saves
  time on every run.
  """
  def start do
    {:ok, _} = :application.ensure_all_started(:elixir)
    _ = :application.start(:logger)
    Preload.record("start")

    status =
      try do
        run()
      catch
        kind, reason ->
          IO.puts(:stderr, Exception.format(kind, reason, __STACKTRACE__))
          @use_mix
      end

    Preload.save()
    System.halt(status)
  end

  defp run do
    with {:ok, project} <- read_project(),
         {:ok, lib_files} <- lib_files(),
         {:ok, test_file} <- test_file(),
         :ok <- check_sources([test_file, "test/test_helper.exs" | lib_files]) do
      run(project, lib_files, test_file)
    else
      :use_mix -> @use_mix
    end
  end

  defp run(project, lib_files, test_file) do
    # Parse the metadata and rewrite the test file in a second process,
    # while this one compiles the solution.
    prepare = Task.async(fn -> prepare_test_file(test_file) end)
    Preload.record("checks")

    case compile_solution(project, lib_files) do
      {:ok, modules} ->
        Preload.record("compiled")
        :ok = Task.await(prepare, :infinity)
        Preload.record("prepared")

        if Enum.any?(modules, &helper_module?/1) do
          @use_mix
        else
          start_application(project, modules)
          Preload.record("app started")
          run_tests(project, test_file)
          Preload.record("tests run")
          write_results()
          Preload.record("results written")
          0
        end

      :error ->
        Task.shutdown(prepare, :brutal_kill)
        @compile_error
    end
  end

  ## Checks

  # Accepts only a mix.exs with the shape used by the track's exercises:
  # app, version, an optional elixir requirement, start_permanent,
  # `deps: deps()` with an empty list, and only extra_applications in
  # application/0. Any of the directories checked below means the project
  # needs something only Mix does.
  defp read_project do
    with {:ok, source} <- File.read("mix.exs"),
         {:ok, ast} <- Code.string_to_quoted(source),
         {:defmodule, _, [_name, [do: {:__block__, _, body}]]} <- ast,
         [use_mix | defs] <- body,
         {:use, _, [{:__aliases__, _, [:Mix, :Project]}]} <- use_mix,
         {:ok, project} <- project_fun(defs),
         {:ok, extra_apps} <- application_fun(defs),
         :ok <- deps_fun(defs),
         3 <- length(defs),
         false <- File.exists?("config"),
         false <- File.exists?("src"),
         false <- File.exists?("_build"),
         false <- File.exists?("deps") do
      {:ok, Map.put(project, :extra_applications, extra_apps)}
    else
      _ -> :use_mix
    end
  end

  defp project_fun(defs) do
    with [kw] <-
           for({:def, _, [{:project, _, ctx}, [do: kw]]} when ctx in [nil, []] <- defs, do: kw),
         true <- is_list(kw) and Keyword.keyword?(kw),
         [] <- Keyword.keys(kw) -- [:app, :version, :elixir, :start_permanent, :deps],
         app when is_atom(app) and app != nil <- kw[:app],
         version when is_binary(version) <- kw[:version],
         true <- Version.parse(version) != :error,
         {:deps, _, ctx} when ctx in [nil, []] <- kw[:deps],
         true <- start_permanent_ok?(kw),
         true <- elixir_requirement_ok?(kw) do
      {:ok, %{app: app, version: version}}
    else
      _ -> :error
    end
  end

  # Only `start_permanent: Mix.env() == :prod`, which is false in tests.
  defp start_permanent_ok?(kw) do
    case Keyword.fetch(kw, :start_permanent) do
      :error -> true
      {:ok, {:==, _, [{{:., _, [{:__aliases__, _, [:Mix]}, :env]}, _, []}, :prod]}} -> true
      _ -> false
    end
  end

  # Mix fails if the Elixir version doesn't match, so let Mix report that.
  defp elixir_requirement_ok?(kw) do
    case Keyword.fetch(kw, :elixir) do
      :error -> true
      {:ok, req} when is_binary(req) -> Version.match?(System.version(), req)
      _ -> false
    end
  end

  defp application_fun(defs) do
    with [kw] <-
           for(
             {:def, _, [{:application, _, ctx}, [do: kw]]} when ctx in [nil, []] <- defs,
             do: kw
           ),
         [extra_applications: apps] <- kw,
         true <- is_list(apps) and Enum.all?(apps, &is_atom/1) do
      {:ok, apps}
    else
      _ -> :error
    end
  end

  defp deps_fun(defs) do
    case for({:defp, _, [{:deps, _, ctx}, [do: deps]]} when ctx in [nil, []] <- defs, do: deps) do
      [[]] -> :ok
      _ -> :error
    end
  end

  # The same files `mix compile` would compile.
  defp lib_files do
    case Path.wildcard("lib/**/*.ex") do
      [] -> :use_mix
      files -> {:ok, files}
    end
  end

  # `mix test` loads test/**/*_test.exs, ignores *_helper.exs and warns about
  # anything else. The runner handles exactly one test file plus test_helper.exs.
  defp test_file do
    files = Path.wildcard("test/**/*.{ex,exs}")

    case Enum.split_with(files, &String.ends_with?(&1, "_test.exs")) do
      {[test_file], ["test/test_helper.exs"]} -> {:ok, test_file}
      _ -> :use_mix
    end
  end

  # Code that calls Mix, or reads config at compile time, needs a real Mix project.
  defp check_sources(files) do
    if Enum.any?(files, &(File.read!(&1) =~ ~r/\bMix\b|compile_env/)) do
      :use_mix
    else
      :ok
    end
  end

  defp helper_module?(module) do
    name = Atom.to_string(module)
    Enum.any?(@helper_prefixes, &String.starts_with?(name, &1))
  end

  ## Preparing the test file

  # Does what `exercism_test_helper --parse-meta` and `--transform` do.
  defp prepare_test_file(test_file) do
    source = File.read!(test_file)

    metadata = source |> Meta.TestParser.parse() |> Jason.encode!()
    File.write!("metadata.json", metadata)

    File.write!(test_file, TestSource.Transformer.transform_test(source))
    :ok
  end

  ## Compiling the solution

  defp app_path(project), do: Path.expand("_build/test/lib/#{project.app}")
  defp ebin(project), do: Path.join(app_path(project), "ebin")

  defp compile_solution(project, lib_files) do
    ebin = ebin(project)
    File.mkdir_p!(ebin)
    Code.prepend_path(ebin)

    # `mix compile` used to run in its own VM, so nothing printed while
    # compiling reached the test output. Send it to a throwaway device.
    {:ok, null} = StringIO.open("")
    group_leader = Process.group_leader()
    Process.group_leader(self(), null)

    result =
      try do
        Kernel.ParallelCompiler.compile_to_path(lib_files, ebin, return_diagnostics: true)
      after
        Process.group_leader(self(), group_leader)
      end

    case result do
      {:ok, modules, _diagnostics} -> {:ok, modules}
      {:error, _errors, _diagnostics} -> :error
    end
  end

  # Writes the .app file as `mix compile.app` does, and loads it, so that
  # stack traces show the app's name and version as before. Then it
  # consolidates protocols and starts the application and its dependencies.
  defp start_application(project, modules) do
    properties = [
      description: to_charlist(project.app),
      modules: Enum.sort(modules),
      registered: [],
      vsn: to_charlist(project.version),
      applications: [:kernel, :stdlib, :elixir | project.extra_applications],
      optional_applications: []
    ]

    spec = {:application, project.app, properties}
    File.write!(Path.join(ebin(project), "#{project.app}.app"), :io_lib.format("~tp.~n", [spec]))
    :ok = :application.load(spec)

    consolidate_protocols(project, modules)

    {:ok, _} = Application.ensure_all_started(project.app)
  end

  # Protocol consolidation makes protocol calls fast, and `mix compile` does it
  # for every protocol in the code path, which takes a while. The image already
  # holds consolidated copies of Elixir's own protocols (built by
  # `bin/build-consolidated.sh` when the image is built). Here the runner only
  # consolidates the protocols defined or implemented by the solution.
  defp consolidate_protocols(project, modules) do
    # Read the attributes from the .beam files, which (as with
    # Protocol.extract_impls/2) doesn't load the modules.
    protocols =
      modules
      |> Enum.flat_map(fn module ->
        beam = Path.join(ebin(project), "#{module}.beam") |> String.to_charlist()
        {:ok, {^module, [attributes: attributes]}} = :beam_lib.chunks(beam, [:attributes])

        protocol_of(module, attributes)
      end)
      |> Enum.uniq()

    output = Path.join(app_path(project), "consolidated")
    File.mkdir_p!(output)

    if protocols != [] do
      paths = consolidation_paths()

      for protocol <- protocols do
        impls = Protocol.extract_impls(protocol, paths)
        {:ok, binary} = Protocol.consolidate(protocol, impls)
        File.write!(Path.join(output, "#{protocol}.beam"), binary)
      end
    end

    # Put the consolidated protocols first in the code path, as Mix does,
    # and reload any protocol that is already loaded. The solution's own
    # consolidated protocols go first, because they include its implementations.
    prebuilt = System.fetch_env!("EXERCISM_CONSOLIDATED")
    Code.prepend_path(prebuilt)
    Code.prepend_path(output)

    for dir <- [prebuilt, output],
        file <- File.ls!(dir),
        Path.extname(file) == ".beam",
        module = String.to_atom(Path.rootname(file)),
        :code.is_loaded(module) != false do
      :code.purge(module)
      {:module, ^module} = :code.load_file(module)
    end

    :ok
  end

  defp protocol_of(module, attributes) do
    cond do
      Keyword.has_key?(attributes, :__protocol__) -> [module]
      impl = attributes[:__impl__] -> [Keyword.fetch!(impl, :protocol)]
      true -> []
    end
  end

  # The paths Mix uses for consolidation (everything in the code path outside
  # OTP), except for this helper and Jason, which `mix compile` doesn't see.
  defp consolidation_paths do
    otp = :code.lib_dir()
    helper = [:code.which(__MODULE__), :code.which(Jason)] |> Enum.map(&:filename.dirname/1)

    for path <- :code.get_path(),
        not :lists.prefix(otp, path),
        path not in helper,
        do: path
  end

  ## Running the tests

  defp run_tests(project, test_file) do
    # The ExUnit options set by `mix test --seed 0 --exclude slow --formatter JSONFormatter`.
    Application.ensure_loaded(:ex_unit)
    ex_unit_opts = [autorun: false, seed: 0, exclude: [:slow], formatters: [JSONFormatter]]
    ExUnit.configure(ex_unit_opts)

    Code.with_diagnostics([log: true], fn -> Code.require_file("test/test_helper.exs") end)

    # As `mix test` does, add any excludes set by test_helper.exs, and set
    # the path of the failures manifest.
    helper_excludes = List.wrap(Application.get_env(:ex_unit, :exclude, []))
    manifest = Path.join([app_path(project), ".mix", ".mix_test_failures"])

    ex_unit_opts
    |> Keyword.update(:exclude, helper_excludes, &Enum.uniq(&1 ++ helper_excludes))
    |> Keyword.put(:failures_manifest_path, manifest)
    |> ExUnit.configure()

    # From here on, this does what Mix.Compilers.Test.require_and_run/4 does:
    # it starts ExUnit, compiles the test file and waits for the tests to finish.
    previous = Code.compiler_options(docs: false, debug_info: false, infer_signatures: false)
    Application.ensure_all_started(:ex_unit)
    task = ExUnit.async_run()
    Preload.record("ex_unit started")

    case Kernel.ParallelCompiler.require([test_file], return_diagnostics: true) do
      {:ok, _, _} ->
        Preload.record("test file compiled")
        ExUnit.await_run(task)
        Code.compiler_options(previous)
        :ok

      {:error, _, _} ->
        # `mix test` stops here without writing results.json, and so does the runner.
        Task.shutdown(task)
        System.halt(0)
    end
  end

  ## Building results.json

  # Does what `exercism_test_helper --log-to-json` and `--combine` do.
  defp write_results do
    flush_stdout()

    OutputLogToJSON.run(["output", "output.json"])
    CombineJSON.run(["results.json", "metadata.json", "output.json"])
  end

  # The VM's stdout goes to the `output` file. Make sure everything written so
  # far, by the tests and by Logger, has reached the file before reading it.
  defp flush_stdout do
    for %{id: id, module: :logger_std_h} <- :logger.get_handler_config(),
        do: :logger_std_h.filesync(id)

    _ = :io.getopts(:user)
    :ok
  end
end
