defmodule ChessPlus.Flow.Duel.Rematch do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Color
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:duel, :rematch}, %{duel: {:some, duel_id}} = sender) do
    Duel.update(duel_id, fn duel ->
      duelists = Duel.map_duelists(duel, fn duelist -> %{duelist | color: Color.inverse(duelist.color)} end)

      {:ok, duel} = ChessPlus.Rocks.Territories.retrieve(:classic) # TODO embed territory in duel data to rematch current territory

      {:ok, %Duel{
        duel |
        id: duel_id,
        duelists: duelists
      }}
    end)
    |> Result.map(fn duel ->
      waves = Duel.map_duelists(duel, fn duelist ->
        [
          {:event, duelist, {{:event, :duel_joined}, duel.id}},
          {:tcp, duelist, {{:duel, :add}, duel}}
        ]
      end)
      |> Enum.flat_map(&(&1))

      [
        {:event, sender, {{:event, :duel_created}, duel}} |
        waves
      ]
    end)

  end
end
