defmodule ChessPlus.Flow.Duel.RequestRematch do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result
  alias ChessPlus.Option

  @spec flow(wave, sender) :: Result.result
  def flow({:duelist, :request_rematch}, %{duel: {:some, duel_id}} = sender) do
    Duel.update(duel_id, fn duel ->
      Duel.fetch_player_color(duel, sender)
      |> Option.map(fn color ->
        Duel.update_duel_state(duel, fn
          {:ended, {:request_rematch, _}} = duel_state -> duel_state
          _ -> {:ended, {:request_rematch, color}}
        end)
      end)
      |> Option.to_result()
    end)
    |> Result.map(fn duel ->
      Duel.map_duelists(duel, fn duelist ->
        {:udp, duelist, {{:duel_state, :update}, duel.duel_state}}
      end)
    end)
  end
end
