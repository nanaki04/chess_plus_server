defmodule ChessPlus.Flow.Duel.UpdateDuelState do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel

  @impl(ChessPlus.Wave)
  def flow({{:event, :piece_moved}, _}, player) do
    {:ok, []}
  end
end
