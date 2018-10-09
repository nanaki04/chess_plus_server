defmodule ChessPlus.Flow.Duel.AcceptRemise do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:duelist, :remise}, %{duel: {:some, duel_id}} = sender) do
    Duel.update(duel_id, fn duel ->
      Duel.update_duel_state(duel, {:ended, :remise})
      |> Result.retn()
    end)
    |> Result.map(fn duel ->
      :ok = Duel.stop_gracefully(duel_id, true)

      commands = Duel.map_duelists(duel, fn p ->
        [
          {:tcp, p, {{:duel_state, :update}, duel.duel_state}},
          {:event, p, {{:event, :duel_left}, duel.id}}
        ]
      end)
      |> Enum.flat_map(&(&1))

      [
        {:event, sender, {{:event, :duel_deleted}, duel}} |
        commands
      ]
    end)
  end

  def flow(_, _), do: {:ok, []}

end
