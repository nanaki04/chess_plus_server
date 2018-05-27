defmodule ChessPlus.Flow.Player.LeaveDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_left}, _}, player) do
    Player.update!(player.id, fn p -> %Player{
      p |
      duel: :none
    } end)

    {:ok, []}
  end
end
