NimbleCSV.define(MyParser, separator: ",", escape: ~S'"')

# stdio = IO.read(:stdio, :all) |> IO.inspect(label: "3") |> MyParser.parse_string() |> IO.inspect(label: "3")

:stdio
|> IO.stream(:line)
|> MyParser.parse_stream(skip_headers: false)
|> Enum.to_list()
|> IO.inspect(label: "9")
