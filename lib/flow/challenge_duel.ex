defmodule ChessPlus.Flow.ChallengeDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @spec invoke(Duel.duel, receiver) :: wave_downstream
  def invoke(%{duelists: _} = amplitude, receiver) do
    {:udp, receiver, {{:duelist, :add}, amplitude}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({{:duelist, :join}, %{player: player, id: id}}, _) do
    duelist = Duel.Duelist.from_player(player)
    duel = Duel.update(id, fn
      %{duelists: []} = duel ->
        %{duel | duelists: [Duel.Duelist.with_color(duelist, :white)]}
      %{duelists: [p1]} = duel ->
        %{duel | duelists: [p1, Duel.Duelist.with_color(duelist, :black)]}
    end)
    duel_state = ChessPlus.Flow.InitiateDuel.invoke(duel, player)
    case duel.duelists do
      [p1, p2] -> [duel_state, invoke(p2, p1)]
      _ -> [duel_state]
    end
    |> Result.retn()
  end
  def flow(_), do: {:error, "Failed to parse ChallengeDuel wave"}

end
