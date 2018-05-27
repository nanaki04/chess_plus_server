defmodule ChessPlus.Flow.Duel.LeaveDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Option
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({{:event, :player_deleted}, %{duel: {:some, duel_id}} = player}, _) do
    duel_id
    |> Duel.fetch()
    |> (fn duel ->

      :ok = Duel.stop_gracefully(duel_id, true)

      commands = Duel.map_opponent(duel, fn p ->
        [
          {:udp, p, {{:global, :error}, "Opponent vanished"}},
          {:event, p, {{:event, :duel_left}, duel.id}}
        ]
      end, player)
      |> Enum.flat_map(fn c -> c end)

      {:ok, [
        {:event, player, {{:event, :duel_deleted}, duel}} |
        commands
      ]}
    end).()
  end

  def flow(_, _), do: {:ok, []}

end
