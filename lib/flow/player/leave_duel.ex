defmodule ChessPlus.Flow.Player.LeaveDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_left}, _}, player) do
    if Player.active?(player.id) do
      Player.update!(player.id, fn p -> %Player{
        p |
        duel: :none
      } end)
    end

    {:ok, []}
  end
end
