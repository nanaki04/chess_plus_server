defmodule ChessPlus.Flow.Duel.Join do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  import ChessPlus.Result, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:duelist, :join}, %{id: id}}, sender) do
    verify_duel(id)
    <|> fn id -> join_duel(id, sender) end
  end

  defp verify_duel(id) do
    if Duel.active?(id) do
      {:ok, id}
    else
      {:error, "Duel does not exist"}
    end
  end

  defp join_duel(id, player) do
    duelist = Duel.Duelist.from_player(player)
    |> Duel.Duelist.with_color(:black)

    duel = Duel.update(id, fn d -> %Duel{
      duelists: [duelist | d.duelists]
    } end)

    {:ok, [
      {:event, player, {{:event, :duel_joined}, duel.id}},
      {:udp, Enum.fetch(duel.duelists, 1), {{:duelist, :add}, %{duelist: duelist}}},
      {:tcp, player, {{:duel, :add}, duel}}
    ]}
  end
end
