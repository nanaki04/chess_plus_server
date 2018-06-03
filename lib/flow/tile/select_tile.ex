defmodule ChessPlus.Flow.SelectTile do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result
  alias LifeBloom.Bloom
  import ChessPlus.Result, only: [<|>: 2, ~>>: 2]

  @spec invoke(Duel.color, Duel.coordinate, receiver) :: wave_downstream
  def invoke(player, coordinate, receiver) do
    {:udp, receiver, {{:tile, :confirm_select}, %{player: player, coordinate: coordinate}}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({{:tile, :select}, %{coordinate: coordinate}}, sender) do
    color = Duel.map_player(sender, fn player -> player.color end)

    ChessPlus.Flow.DeselectTile.flow({:tile, :deselect}, sender)

    {:ok, sender}
    ~>> fn s -> Duel.update_tile(s, coordinate, fn t -> Map.put(t, :selected_by, {:some, color}) end) end
    <|> fn s -> Duel.map_duelists(s, Bloom.sow(&invoke/3, color, coordinate)) end
  end

end
