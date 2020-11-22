defmodule ExercismTestHelper.CLI.Command.OutputLogToJSON do
  def run(file) do
    json =
      file
      |> File.read!()
      |> String.split("[test started] ", trim: true)
      |> Enum.map(&String.split(&1, "\n", trim: true))
      |> Enum.map(fn [n | os] -> {n, os |> Enum.join("\n")} end)
      |> Enum.into(%{})
      |> Jason.encode!()

    File.write!(file <> ".json", json)
  end
end
