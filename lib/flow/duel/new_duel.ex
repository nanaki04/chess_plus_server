defmodule ChessPlus.Flow.Duel.New do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  import ChessPlus.Result, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:duel, :new}, %{map: map}}, sender) do
    # TODO use result
    {:ok, duel} = ChessPlus.Rocks.Territories.retrieve(map)
    duelist = Duel.Duelist.from_player(sender)
    |> Duel.Duelist.with_color(:white)

    duel = Duel.update(sender.id, fn %{id: id} -> %Duel{
      duel |
      id: id,
      duelists: [duelist]
    } end)

    {:ok, [
      {:event, sender, {{:event, :duel_created}, duel}},
      {:event, sender, {{:event, :duel_joined}, duel.id}},
      {:tcp, sender, {{:duel, :add}, duel}}
    ]}
  end
end
