ExUnit.start()
ExUnit.configure(formatters: [ElixirTestRunner.JSONFormatter], json_path: "./results.json")
