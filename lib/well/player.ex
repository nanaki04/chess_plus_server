defmodule ChessPlus.Well.Player do
  use ChessPlus.Well
  alias __MODULE__, as: Player

  @type player :: %Player{
    name: String.t,
    ip: {number, number, number, number},
    port: number,
    tcp_port: port
  }

  defstruct name: "",
    ip: nil,
    port: 0,
    tcp_port: nil

  @impl(Guardian.Secret)
  def make_initial_state(id) do
    %Player{name: id}
  end

  def is_complete?(player) do
    String.length(player.name) > 0
    and player.ip != nil
    and player.port > 0
    and player.tcp_port != nil
  end

  def terminate(:normal, _), do: :ok

end
