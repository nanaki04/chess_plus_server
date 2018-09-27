defmodule ChessPlus.Flow.Buff.RefreshBuffs do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Buff
  alias ChessPlus.Result

  @impl(ChessPlus.Wave)
  def flow({{:event, :piece_moved}, _}, %{duel: {:some, id}}) do
    Duel.update(id, fn duel ->
      duel
      |> Buff.decrement_turn_durations()
      |> Result.bind(&Buff.remove_expired_buffs/1)
    end)
    |> Result.bind(fn duel ->
      Duel.map_duelists(duel, fn duelist ->
        {:tcp, duelist, {{:buffs, :update}, duel.buffs.active_buffs}}
      end)
    end)
  end
end
