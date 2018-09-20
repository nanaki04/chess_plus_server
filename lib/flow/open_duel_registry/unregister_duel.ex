defmodule ChessPlus.Flow.OpenDuelRegistry.UnregisterDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry
  alias ChessPlus.Well.Duel

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_deleted}, duel}, _) do
    OpenDuelRegistry.unregister(duel.id)

    {:ok, []}
  end

  @impl(ChessPlus.Wave)
  def flow({{:event, :duel_joined}, duel_id}, _) do
    # TODO make an event for when a duel is full, to prevent the use of the Duel well here
    if Duel.is_full?(duel_id), do: OpenDuelRegistry.unregister(duel_id)

    {:ok, []}
  end

end
