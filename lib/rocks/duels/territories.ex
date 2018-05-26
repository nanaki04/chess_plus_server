defmodule ChessPlus.Rocks.Territories do

  @spec retrieve(ChessPlus.Well.Duel.territory) :: ChessPlus.Result.result
  def retrieve(:classic) do
    ChessPlus.Rock.Duel.Classic.retrieve()
  end

  def retrieve(:debug) do
    ChessPlus.Rock.Duel.Debug.retrieve()
  end

  def retrieve(map), do: {:error, "No such territory found: " <> to_string(map)}

end
