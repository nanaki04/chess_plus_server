defmodule ChessPlus.Flow.Login do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player
  alias ChessPlus.Well.PlayerRegistry
  alias ChessPlus.Result

  @spec invoke_logged_in(Player.player, receiver) :: wave_downstream
  def invoke_logged_in(player, receiver) do
    {:udp, receiver, {{:player, :add}, player}}
  end

  @spec invoke_created(Player.player, receiver) :: wave_downstream
  def invoke_created(player, receiver) do
    {:udp, receiver, {{:player, :created}, player}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({{:player, :join}, %{name: name}}, {:udp, %{ip: ip, port: port}} = sender) do
    PlayerRegistry.start_child(make_id(sender), name)
    Player.update(name, fn p -> %Player{
      p |
      name: name,
      ip: ip,
      port: port
    } end)
    |> (&[invoke_created(&1, &1)]).()
    |> Result.retn()
  end

  def flow({{:player, :join}, %{name: name}}, {:tcp, %{port: port}}) do
    PlayerRegistry.start_child(port, name)
    Player.update(name, fn p -> %Player{
      p |
      name: name,
      tcp_port: port
    } end)
    |> (&[invoke_logged_in(&1, &1)]).()
    |> Result.retn()
  end

  def flow({{:player, :join}, _}, %Player{} = player) do
    {:ok, [invoke_logged_in(player, player)]}
  end

  def make_id({:udp, %{ip: {n1, n2, n3, n4} = ip, port: port}}) do
    ip = Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    ip <> ":" <> to_string(port)
  end

end
