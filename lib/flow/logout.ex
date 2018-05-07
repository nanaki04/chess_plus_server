defmodule ChessPlus.Flow.Logout do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player
  alias ChessPlus.Well.PlayerRegistry
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:player, :remove}, %{name: name} = player) do
    :ok = clear_registry_tcp(player)
    :ok = clear_registry_udp(player)
    :ok = Player.stop_gracefully(name)
    {:ok, []}
  end

  def flow({:player, :remove}, player) do
    :ok = clear_registry_tcp(player)
    {:ok, []}
  end

  defp clear_registry_tcp(%{tcp_port: nil}), do: :ok
  defp clear_registry_tcp(%{tcp_port: port}) do
    PlayerRegistry.terminate_child(port)
  end
  defp clear_registry_tcp({:tcp, %{port: port}}) do
    PlayerRegistry.terminate_child(port)
  end

  defp clear_registry_udp(%{ip: nil}), do: :ok
  defp clear_registry_udp(%{ip: _, port: _} = sender) do
    PlayerRegistry.terminate_child(make_id(sender))
  end
  defp clear_registry_udp(_), do: :ok

  defp make_id(%{ip: {n1, n2, n3, n4}, port: port}) do
    Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    |> Kernel.<>(":" <> to_string(port))
  end

end
