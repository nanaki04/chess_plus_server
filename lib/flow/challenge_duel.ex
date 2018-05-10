defmodule ChessPlus.Flow.ChallengeDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Player
  alias ChessPlus.Result
  import ChessPlus.Result, only: [<|>: 2]

  @spec invoke(Duel.duelist, receiver) :: wave_downstream
  def invoke(duelist, receiver) do
    {:udp, receiver, {{:duelist, :add}, %{duelist: duelist}}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({{:duelist, :join}, %{id: id}}, sender) do
    verify_duel(id)
    <|> fn id -> join_duel(id, sender) end
  end
  def flow(_), do: {:error, "Failed to parse ChallengeDuel wave"}

  defp verify_duel(id) do
    if Duel.active?(id) do
      {:ok, id}
    else
      {:error, "Duel does not exist"}
    end
  end

  defp join_duel(id, player) do
    Player.update(player.id, fn p -> %{p | duel: {:some, id}} end)
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

end
