# Use the Plot struct as it is provided
defmodule Plot do
  @enforce_keys [:plot_id, :registered_to]
  defstruct [:plot_id, :registered_to]
end

# partial solution on purpose

defmodule CommunityGarden do
  def start(opts \\ []) do
    Agent.start(fn -> %{registry: %{}, next_id: 1} end, opts)
  end

  def list_registrations(pid) do
    # Please implement the list_registrations/1 function
  end

  def register(pid, register_to) do
    # Please implement the register/2 function
  end

  def release(pid, plot_id) do
    # Please implement the release/2 function
  end

  def get_registration(pid, plot_id) do
    # Please implement the get_registration/2 function
  end
end
