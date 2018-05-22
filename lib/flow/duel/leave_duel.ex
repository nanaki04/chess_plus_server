defmodule ChessPlus.Flow.LeaveDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Option
  alias ChessPlus.Result
  import ChessPlus.Option, only: [<|>: 2]

  @spec flow(wave, sender) :: Result.result
  def flow({{:event, :player_deleted}, player}) do
    (player.duel
    <|> (&Duel.fetch/1)
    <|> fn duel ->

      :ok = Duel.stop_gracefully(player.duel, true)

      commands = Duel.map_opponent(duel, fn p ->
        [
          {:udp, p, {{:global, :error}, "Opponent vanished"}},
          {:event, p, {{:event, :duel_left}, duel.id}}
        ]
      end)
      |> Enum.flat_map(fn c -> c end)

      {:ok, [
        {:event, player, {{:event, :duel_deleted}, duel}} |
        commands
      ]}
    end)
    |> Option.or_else({:ok, []})
  end

end
