defmodule ChessPlus.Rock.Duel.Debug do
  alias ChessPlus.Well.Rules
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Row
  alias ChessPlus.Well.Duel.Column
  alias ChessPlus.Result
  alias ChessPlus.Matrix
  import ChessPlus.Result, only: [<|>: 2, <~>: 2]

  @behaviour ChessPlus.Rock

  @impl(ChessPlus.Rock)
  def retrieve() do
    rules = build_rules()
    pieces = build_piece_templates(rules)
    build_tiles()
    <|> fn tiles -> place_pieces(tiles, pieces) end
    <|> fn tiles -> %Duel{
      duelists: [],
      board: %{ tiles: tiles },
      rules: rules
    } end
  end

  def build_rules() do
    [Rules.new_move({2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]})]
    ++ [Rules.new_move({-2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]})]
    ++ [Rules.new_move({1, 0})]
    ++ [Rules.new_move({0, 1})]
    ++ [Rules.new_move({-1, 0})]
    ++ [Rules.new_move({0, -1})]
    ++ (1..150 |> Enum.flat_map(fn _ -> Rules.gen_and_quadra_mirror_moves({1, 1}, 2) end))
    |> Rules.to_map()
  end

  def build_tiles() do
    rows = 1..12
           |> Enum.map(&Row.from_num/1)
           |> Result.unwrap

    cols = 1..12
           |> Enum.map(&Column.from_num/1)
           |> Result.unwrap

    case {rows, cols} do
      {{:ok, rows}, {:ok, cols}} -> {:ok, Matrix.initialize(rows, cols, %{piece: :none, selected_by: :none, conquerable_by: :none, color: :white})}
      {{:error, err}, _} -> {:error, err}
      {_, {:error, err}} -> {:error, err}
    end
    <|> fn tiles ->
      Matrix.map(tiles, fn row, col, tile ->
        ({:ok, &(if rem(&1 + &2, 2) == 0, do: :white, else: :black)}
        <~> Row.to_num(row)
        <~> Column.to_num(col)
        <|> &%{tile | color: &1})
        |> Result.or_else(tile)
      end)
    end
  end

  def build_piece_templates(rules) do
    black = %{
      pawn: {:pawn, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {1, 0}}} -> true
          {:move, %{offset: {1, 1}}} -> true
          {:conquer, %{offset: {1, x}}} -> x == -1 or x ==1
          _ -> false
        end)
      }}
    }

    white = %{
      pawn: {:pawn, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {-2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {-1, 0}}} -> true
          {:conquer, %{offset: {-1, x}}} -> x == -1 or x ==1
          _ -> false
        end)
      }}
    }

    %{
      black: black,
      white: white
    }
  end

  def place_pieces(tiles, pieces) do
    tiles
    |> Matrix.update(:one, :a, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:one, :b, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:one, :c, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:three, :a, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:three, :b, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:three, :c, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
  end
end
