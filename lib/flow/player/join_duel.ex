defmodule ChessPlus.Flow.Player.JoinDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_joined}, id}, player) do
    Player.update!(player.id, fn p -> %Player{
      p |
      duel: {:some, id}
    } end)

    {:ok, []}
  end
end
