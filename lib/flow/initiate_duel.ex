defmodule ChessPlus.Flow.InitiateDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Player
  alias ChessPlus.Result
  import ChessPlus.Result, only: [<|>: 2]

  @spec invoke(Duel.duel, Player.player) :: wave_downstream
  def invoke(duel, receiver) do
    {:tcp, receiver, {{:duel, :add}, duel}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({{:duel, :new}, %{map: map}}, sender) do
    ChessPlus.Logger.log(sender)
    ChessPlus.Rocks.Territories.retrieve(map)
    <|> fn duel ->
      Duel.update(make_id(sender), fn %{id: id} ->
        %{duel | id: id, duelists: [Duel.Duelist.from_player(sender) |> Duel.Duelist.with_color(:white)]}
      end)
    end
    <|> fn duel -> [invoke(duel, sender)] end
  end

  @spec make_id(Player.player) :: String.t
  defp make_id(%{ip: {n1, n2, n3, n4}, port: port}) do
    Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    |> Kernel.<>(":" <> to_string(port))
  end

end
