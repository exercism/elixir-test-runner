defmodule Meta.TestParser.TestSuite do
  @derive {Jason.Encoder, only: [:tests]}
  defstruct [:description, :task_id, :exclude, tests: []]
end
