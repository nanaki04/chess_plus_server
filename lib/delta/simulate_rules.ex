defmodule ChessPlus.Delta.SimulateRules do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Duel.Coordinate
  alias ChessPlus.Well.Duel.Buff
  alias ChessPlus.Well.Rules
  alias ChessPlus.Result
  alias ChessPlus.Option
  import ChessPlus.Option, only: [<|>: 2, ~>>: 2, <~>: 2]

  @type rule :: Rules.rule
  @type duel :: Duel.duel
  @type piece :: Duel.piece
  @type pieces :: Duel.pieces

  @spec simulate_rule(duel, rule, Option.option) :: Result.result
  def simulate_rule(_, {:move, _}, :none), do: {:error, "No piece to simulate move rule"}
  def simulate_rule(_, {:conquer, _}, :none), do: {:error, "No piece to simulate conquer rule"}
  def simulate_rule(_, {:move_combo, _}, :none), do: {:error, "No piece to simulate move combo rule"}
  def simulate_rule(_, {:conquer_combo, _}, :none), do: {:error, "No piece to simulate conquer combo rule"}
  def simulate_rule(_, {:promote, _}, :none), do: {:error, "No piece to simulate promote rule"}
  def simulate_rule(_, {:add_buff, _}, :none), do: {:error, "No piece to simulate add buff rule"}
  def simulate_rule(duel, {:move, %{offset: offset}}, {:some, piece}) do
    (Piece.find_piece_coordinate(duel, piece)
    |> IO.inspect(label: "piece coord")
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
  def simulate_rule(duel, {:move_combo, %{other: other, my_movement: my_movement, other_movement: other_movement}}, {:some, piece}) do
    maybe_own_coord = Piece.find_piece_coordinate(duel, piece)
    maybe_other_coord = Coordinate.apply_offset(maybe_own_coord, other)
    maybe_own_destination = Coordinate.apply_offset(maybe_own_coord, my_movement)
    maybe_other_destination = Coordinate.apply_offset(maybe_other_coord, other_movement)

    if Duel.has_tiles?(duel, [maybe_own_destination, maybe_other_destination]) do
      ({:some, fn own_coord, own_destination, other_coord, other_destination ->
        duel
        |> Duel.move_piece(own_coord, own_destination)
        |> Result.bind(fn d -> Duel.move_piece(d, other_coord, other_destination) end)
      end}
      <~> maybe_own_coord
      <~> maybe_own_destination
      <~> maybe_other_coord
      <~> maybe_other_destination)
      |> Option.to_result()
      |> Result.flatten()
    else
      {:ok, duel}
      # TODO why did I return an error here??
      # {:error, "One or more of the target coordinates do not exist"}
    end
  end
  def simulate_rule(duel, {:conquer_combo, %{target_offset: target_offset, my_movement: my_movement}}, {:some, piece}) do
    maybe_own_coord = Piece.find_piece_coordinate(duel, piece)
    maybe_target_coord = Coordinate.apply_offset(maybe_own_coord, target_offset)
    maybe_destination = Coordinate.apply_offset(maybe_own_coord, my_movement)

    if Duel.has_tiles?(duel, [maybe_target_coord, maybe_destination]) do
      ({:some, fn own_coord, target_coord, destination ->
        duel
        |> Duel.move_piece(own_coord, destination)
        |> Result.bind(fn d -> Duel.update_tile(d, target_coord, fn tile -> %{tile | piece: :none} end) end)
      end}
      <~> maybe_own_coord
      <~> maybe_target_coord
      <~> maybe_destination)
      |> Option.to_result()
      |> Result.flatten()
    else
      {:ok, duel}
    end
  end
  def simulate_rule(duel, {:promote, %{ranks: rank}}, {:some, {_, %{id: id, color: color}}}) do
    Duel.update_piece_by_id(duel, id, fn
      {:some, piece} ->
        Piece.rank_to_type(rank)
        |> Result.bind(fn type ->
          Option.to_result(Piece.find_template(duel, color, type), "Piece template not found")
        end)
        |> Result.map(fn template -> {:some, Piece.merge_template(piece, template)} end)
        |> Result.or_else({:some, piece})
      :none ->
        :none
    end)
  end
  def simulate_rule(duel, {:add_buff_on_move, %{target_offset: target_offset, buff_id: buff_id}}, {:some, piece}) do
    maybe_own_coord = Piece.find_piece_coordinate(duel, piece)
    maybe_target_coord = Coordinate.apply_offset(maybe_own_coord, target_offset)
    maybe_target = Option.bind(maybe_target_coord, fn coord -> Duel.fetch_piece(duel, coord) end)

    ({:some, fn target -> Buff.add_buff(duel, buff_id, target.id) end}
    <~> maybe_target)
    |> Option.or_else(duel)
    |> Result.retn()
  end
  def simulate_rule(_, _, _), do: {:error, "No simulation available for rule"}
end
