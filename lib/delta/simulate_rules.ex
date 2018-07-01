defmodule ChessPlus.Delta.SimulateRules do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Duel.Coordinate
  alias ChessPlus.Well.Rules
  alias ChessPlus.Result
  alias ChessPlus.Option
  import ChessPlus.Option, only: [<|>: 2, ~>>: 2]

  @type rule :: Rules.rule
  @type duel :: Duel.duel
  @type piece :: Duel.piece
  @type pieces :: Duel.pieces

  @spec simulate_rule(duel, rule, Option.option) :: Result.result
  def simulate_rule(_, {:move, _}, :none), do: {:error, "No piece to simulate move rule"}
  def simulate_rule(_, {:conquer, _}, :none), do: {:error, "No piece to simulate conquer rule"}
  def simulate_rule(duel, {:move, %{offset: offset}}, {:some, piece}) do
    (Piece.find_piece_coordinate(duel, piece)
    ~>> fn coord -> (Coordinate.apply_offset(coord, offset) |> Option.from_result()) <|> &{coord, &1} end
    <|> fn {from, to} ->
      if Duel.has_tile?(duel, to) do
        Duel.move_piece(duel, from, to)
      else
        {:error, "Target coordinate does not exist"}
      end
    end)
    |> Option.or_else({:error, "Failed to simulate rule"})
  end
  def simulate_rule(duel, {:conquer, rule_content}, piece), do: simulate_rule(duel, {:move, rule_content}, piece)
  def simulate_rule(_, _, _), do: {:error, "No simulation available for rule"}

end
