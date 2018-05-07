defmodule ChessPlus.Bridge.PlayerFinder do
  use PathFinder.Gatekeeper
  alias ChessPlus.Result
  alias ChessPlus.Well.Player
  import ChessPlus.Result, only: [<|>: 2, ~>>: 2]

  @impl(PathFinder.Gatekeeper)
  def inspect(next) do
    fn state ->
      (ChessPlus.Well.PlayerRegistry.get(Enum.at(state.gifts, 1))
      <|> (&Player.fetch/1)
      ~>> fn player -> if Player.is_complete?(player), do: {:ok, player}, else: {:error, "Player not complete"} end
      <|> fn player ->
        next.(%{state | gifts: List.replace_at(state.gifts, 1, player)})
      end)
      |> Result.or_else_with(fn _ -> next.(state) end)
    end
  end

end
