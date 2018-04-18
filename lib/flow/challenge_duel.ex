defmodule ChessPlus.Flow.ChallengeDuel do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Player

  @type challenge_duel :: {{atom, atom}, %{player: Player.player, id: String.t, map: Duel.territory}}
  @type join_duel :: {{atom, atom}, %{duelist: Duel.duelist}}

  def invoke(%{duelist: _} = amplitude) do
    {{:duelist, :add}, amplitude}
  end

  def flow({_, %{player: player}}, sender) do
    invoke(%{duelist: %{name: player.name, color: :black}})
    |> (&[&1]).()
    |> ChessPlus.Gateway.Udp.out([sender])
    # export
    {:ok, :done}
  end
  def flow(_), do: {:error, "Failed to parse ChallengeDuel wave"}

end
