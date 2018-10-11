defmodule ChessPlus.Flow.Duel.AcceptRemise do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:duelist, :remise}, %{duel: {:some, duel_id}}) do
    Duel.update(duel_id, fn duel ->
      Duel.update_duel_state(duel, {:ended, :remise})
      |> Result.retn()
    end)
    |> Result.map(fn duel ->
      Duel.map_duelists(duel, fn p ->
        [
          {:tcp, p, {{:duel_state, :update}, duel.duel_state}},
        ]
      end)
      |> Enum.flat_map(&(&1))
    end)
  end

  def flow(_, _), do: {:ok, []}

end
