defmodule ExercismFormatter.MixProject do
  use Mix.Project

  def project do
    [
      app: :exercism_formatter,
      version: "0.1.2",
      elixir: "~> 1.9.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:jason, "~> 1.1"}
    ]
  end

  defp escript do
    [main_module: ExercismFormatter.CLI]
  end
end
