defmodule ChessPlus.Flow.DeselectTile do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result
  alias LifeBloom.Bloom
  import ChessPlus.Result, only: [<|>: 2]

  @spec invoke(Duel.color, receiver) :: wave_downstream
  def invoke(player, receiver) do
    {:udp, receiver, {{:tile, :confirm_deselect}, %{player: player}}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({:tile, :deselect}, sender) do
    color = Duel.map_player(sender, fn %{color: color} -> color end)

    sender
    |> Duel.update_tile_where(
      fn tile -> tile.selected_by == color end,
      &Map.put(&1, :selected_by, :none)
    )
    <|> fn duel -> Duel.map_duelists(duel, Bloom.sow(&invoke/2, color)) end
  end

end
