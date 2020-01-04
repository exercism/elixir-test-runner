defmodule OutputFormatter do
  @moduledoc """
  Module containing an Exunit formatter for reporting the start and
  finish of a test run to :stdio.  The purpose is so facilitate the
  capture of test output


  """

  use GenServer

  # Callbacks
  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:test_started, %ExUnit.Test{} = test}, config) do
    IO.puts(:stdio, "[test started] #{test.name}")

    {:noreply, config}
  end

  def handle_cast({:test_finished, %ExUnit.Test{}}, config) do
    IO.puts(:stdio, "[test finished]")

    {:noreply, config}
  end

  def handle_cast(_, config) do
    {:noreply, config}
  end
end
