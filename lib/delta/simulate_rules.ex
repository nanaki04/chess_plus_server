defmodule ChessPlus.Delta.SimulateRules do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Duel.Coordinate
  alias ChessPlus.Well.Rules
  alias ChessPlus.Option
  import ChessPlus.Option, only: [<|>: 2, ~>>: 2]

  @type rule :: Rules.rule
  @type duel :: Duel.duel
  @type piece :: Duel.piece
  @type pieces :: Duel.pieces

  @spec simulate_rule(duel, rule, Option.option) :: duel
  def simulate_rule(duel, {:move, _}, :none), do: duel
  def simulate_rule(duel, {:conquer, _}, :none), do: duel
  def simulate_rule(duel, {:move, %{offset: offset}}, {:some, piece}) do
    (Piece.find_piece_coordinate(duel, piece)
    ~>> fn coord -> Coordinate.apply_offset(coord, offset) |> Option.from_result() <|> &{coord, &1} end
    ~>> fn {from, to} -> Duel.move_piece(duel, from, to) |> Option.from_result() end)
    |> Option.or_else(duel)
  end
  def simulate_rule(duel, {:conquer, rule_content}, piece), do: simulate_rule(duel, {:move, rule_content}, piece)
  def simulate_rule(duel, _, _), do: duel

end
