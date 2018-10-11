defmodule ChessPlus.Flow.Duel.TrackRequestRematchTimeout do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({{:event, :rematch_requested}, %{duel_state: original_duel_state}}, sender) do
    Process.sleep(10000)

    duel = Duel.fetch(sender.id)
    current_duel_state = duel.duel_state

    duel = Duel.update(sender.id, fn duel ->
      Duel.update_duel_state(duel, fn
        {:ended, {:request_rematch, _}} -> original_duel_state
        duel_state -> duel_state
      end)
      |> Result.retn()
    end)

    unless current_duel_state == duel.duel_state do
      Duel.map_duelists(duel, fn duelist ->
        {:tcp, duelist, {{:duel_state, :update}, duel.duel_state}}
      end)
      |> Result.retn()
    else
      {:ok, []}
    end
  end
end
