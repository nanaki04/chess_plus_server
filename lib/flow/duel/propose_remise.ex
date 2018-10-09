defmodule ChessPlus.Flow.Duel.ProposeRemise do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @impl(ChessPlus.Wave)
  def flow({:duelist, :propose_remise}, %{duel: {:some, duel_id}} = sender) do
    duel = Duel.fetch(duel_id)
    Duel.map_opponent(duel, fn opponent ->
      {:udp, opponent, {:duelist, :propose_remise}}
    end, sender)
    |> Result.retn()
  end
end
