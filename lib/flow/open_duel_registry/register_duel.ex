defmodule ChessPlus.Flow.OpenDuelRegistry.RegisterDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_created}, duel}, _) do
    OpenDuelRegistry.register(duel.id)

    {:ok, []}
  end
end
