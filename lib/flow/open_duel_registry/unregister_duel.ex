defmodule ChessPlus.Flow.OpenDuelRegistry.UnregisterDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_deleted}, duel}, _) do
    OpenDuelRegistry.unregister(duel.id)

    {:ok, []}
  end
end
