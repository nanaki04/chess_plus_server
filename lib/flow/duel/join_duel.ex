defmodule ChessPlus.Flow.Duel.Join do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result
  import ChessPlus.Result, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:duelist, :join}, %{id: "any"}}, sender) do
    waves = ChessPlus.Well.OpenDuelRegistry.all()
    |> Enum.reverse() # TODO take newest to prevent hitting ghost games over and over, need to fix ghost games from happening in the first place
    |> Enum.reduce({:error, "No open duels available"}, fn
      id, {:error, _} ->
        verify_player(id, sender)
        |> Result.bind(fn {id, sender} -> join_duel(id, sender) end)
      _, {:ok, _} = result ->
        result
    end)

    case waves do
      {:error, _} ->
        {:ok, [{:tcp, sender, {{:open_duels, :add}, %{duels: []}}}]}
      waves ->
        waves
    end
  end

  def flow({{:duelist, :join}, %{name: id}}, sender) do
    verify_duel(id)
    |> Result.bind(fn id -> verify_player(id, sender) end)
    |> Result.map(fn {id, sender} -> join_duel(id, sender) end)
  end

  defp verify_duel(id) do
    if Duel.active?(id) do
      {:ok, id}
    else
      {:error, "Duel does not exist"}
    end
  end

  defp verify_player(duel_id, player) do
    duel = Duel.fetch(duel_id)
    case Duel.fetch_player(duel, player) do
      :none -> {:ok, {duel_id, player}}
      _ -> {:error, "Player already joined duel"}
    end
  end

  defp join_duel(id, player) do
    duelist = Duel.Duelist.from_player(player)
    |> Duel.Duelist.with_color(:black)

    Duel.update(id, fn
      %Duel{duelists: [_]} = d ->
        {:ok, %Duel{
          d |
          duelists: [duelist | d.duelists]
        }}
      %Duel{duelists: [_, _]} ->
        {:error, "Duel already full"}
      _ ->
        {:error, "Invalid duel"}
    end)
    <|> &[
      {:event, player, {{:event, :duel_joined}, &1.id}},
      {:udp, Enum.fetch!(&1.duelists, 1), {{:duelist, :add}, %{duelist: duelist}}},
      {:tcp, player, {{:duel, :add}, &1}}
    ]
  end
end
