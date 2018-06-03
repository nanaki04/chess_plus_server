defmodule ChessPlus.Flow.PlayerRegistry.RegisterPlayer do
  use ChessPlus.Wave
  alias ChessPlus.Well.PlayerRegistry
  import ChessPlus.Result, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:event, :player_created}, %{name: name, ip: ip, port: port, tcp_port: tcp_port}}, _) do
    (PlayerRegistry.start_child(tcp_port, name)
    <|> fn _ -> PlayerRegistry.start_child(make_id(ip, port), name) end)
    <|> fn _ -> [] end
  end

  def flow(_, _), do: {:ok, []}

  defp make_id({n1, n2, n3, n4}, port) do
    ip = Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    ip <> ":" <> to_string(port)
  end

end
