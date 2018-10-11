defmodule ChessPlus.Flow.Duel.RefuseRemise do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result

  @impl(ChessPlus.Wave)
  def flow({:duelist, :refuse_remise}, %{duel: {:some, duel_id}} = sender) do
    duel = Duel.fetch(duel_id)
    Duel.map_opponent(duel, fn opponent ->
      {:udp, opponent, {:duelist, :refuse_remise}}
    end, sender)
    |> Result.retn()
  end
end
