defmodule ChessPlus.Flow.OpenDuelRegistry.RegisterDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_created}, id}, _) do
    OpenDuelRegistry.register(id)

    {:ok, []}
  end
end
