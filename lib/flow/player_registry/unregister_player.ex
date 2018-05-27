defmodule ChessPlus.Flow.PlayerRegistry.UnregisterPlayer do
  use ChessPlus.Wave
  alias ChessPlus.Well.PlayerRegistry
  import ChessPlus.Result, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:event, :player_deleted}, %{ip: ip, port: port, tcp_port: tcp_port}}, _) do
    (PlayerRegistry.terminate_child(tcp_port)
    <|> fn _ -> PlayerRegistry.terminate_child(make_id(ip, port)) end)
    <|> fn _ -> [] end
  end

  def flow(_, _), do: {:ok, []}

  defp make_id({n1, n2, n3, n4}, port) do
    ip = Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    ip <> ":" <> to_string(port)
  end

end
