efmodule HelloWorld do
  @doc """
  Simply returns "Hello, World!"
  """
  @spec hello :: String.t()
  def hello do
    IO.puts("Hello, sdtout!")
    "Hello, World!"
  end

  def bye do
    IO.puts("Bye, sdtout!")
    nil
  end
end
