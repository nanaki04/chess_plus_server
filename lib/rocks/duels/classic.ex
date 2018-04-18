defmodule ChessPlus.Rock.Duel.Classic do
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
      board: tiles,
      rules: rules
    } end
  end

  defp build_rules() do
    # movements
    # straight movements
    Rules.gen_moves({1, 0}, 7)
    ++ Rules.gen_moves({-1, 0}, 7)
    ++ Rules.gen_moves({0, 1}, 7)
    ++ Rules.gen_moves({0, -1}, 7)
    # angle movements
    ++ Rules.gen_and_quadra_mirror_moves({1, 1}, 7)
    # knight movements
    ++ (Enum.map([{1, 2}, {2, 1}], &Rules.new_move(&1, {:not, {:occupied_by, :any}}))
      |> Rules.quadra_mirror_moves())
    # pawn first moves
    ++ [Rules.new_move({2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]})]
    ++ [Rules.new_move({-2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]})]

    # conquers
    # straight conquers
    ++ Rules.gen_and_mirror_conquers_vertical({1, 0}, 7)
    ++ Rules.gen_and_mirror_conquers_horizontal({0, 1}, 7)
    # angle conquers
    ++ Rules.gen_and_quadra_mirror_conquers({1, 1}, 7)
    # knight conquers
    ++ (Enum.map([{1, 2}, {2, 1}], &Rules.new_conquer(&1, {:is, {:occupied_by, :other}}))
      |> Rules.quadra_mirror_conquers())

    # win conditions
    ++ [{:defeat, %{condition: {:all_of, [{:is, :conquerable}, {:not, :movable}, {:not, :defendable}]}}}]
    ++ [{:remise, %{condition: {:not, :movable}}}]

    |> Rules.to_map()
  end

  def build_tiles() do
    rows = 1..8
    |> Enum.map(&Row.from_num/1)
    |> Result.unwrap

    cols = 1..8
    |> Enum.map(&Column.from_num/1)
    |> Result.unwrap

    case {rows, cols} do
      {{:ok, rows}, {:ok, cols}} -> {:ok, Matrix.initialize(rows, cols, %{piece: :none, selected_by: :none, conquerable_by: :none})}
      {{:error, err}, {:ok, _}} -> {:error, err}
      {{:ok, _}, {:error, err}} -> {:error, err}
    end
    <|> fn tiles ->
      Matrix.map(tiles, fn row, col, tile ->
        ({:ok, &(if rem(&1 + &2, 2) == 0, do: :white, else: :black)}
        <~> Row.to_num(row)
        <~> Column.to_num(col)
        <|> &%{tile | color: &1})
        |> Result.orElse(tile)
      end)
    end
  end

  @spec build_piece_templates(Rules.rules) :: term
  def build_piece_templates(rules) do
    black = %{
      pawn: {:pawn, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {-2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {-1, 0}}} -> true
          {:conquer, %{offset: {-1, x}}} -> x == -1 or x ==1
          _ -> false
        end)
      }},
      king: {:king, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:conquer, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:defeat, _} -> true
          {:move_combo, _} -> true
          _ -> false
        end)
      }},
      queen: {:queen, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) == abs(c) or r == 0 or c == 0
          {:conquer, %{offset: {r, c}}} -> abs(r) == abs(c) or r == 0 or c == 0
          _ -> false
        end)
      }},
      rook: {:rook, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> r == 0 or c == 0
          {:conquer, %{offset: {r, c}}} -> r == 0 or c == 0
          _ -> false
        end)
      }},
      bishop: {:bishop, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) == abs(c)
          {:conquer, %{offset: {r, c}}} -> abs(r) == abs(c)
          _ -> false
        end)
      }},
      knight: {:knight, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> r != 0 and c != 0 and abs(r) != abs(c)
          {:conquer, %{offset: {r, c}}} -> r != 0 and c != 0 and abs(r) != abs(c)
          _ -> false
        end)
      }}
    }

    white = %{
      pawn: {:pawn, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {1, 0}}} -> true
          {:conquer, %{offset: {1, c}}} -> c == -1 or c == 1
          _ -> false
        end)
      }},
      king: {:king, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:conquer, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:defeat, _} -> true
          {:move_combo, _} -> true
          _ -> false
        end)
      }},
      queen: {:queen, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) == abs(c) or r == 0 or c == 0
          {:conquer, %{offset: {r, c}}} -> abs(r) == abs(c) or r == 0 or c == 0
          _ -> false
        end)
      }},
      rook: {:rook, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> r == 0 or c == 0
          {:conquer, %{offset: {r, c}}} -> r == 0 or c == 0
          _ -> false
        end)
      }},
      bishop: {:bishop, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) == abs(c)
          {:conquer, %{offset: {r, c}}} -> abs(r) == abs(c)
          _ -> false
        end)
      }},
      knight: {:knight, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> r != 0 and c != 0 and abs(r) != abs(c)
          {:conquer, %{offset: {r, c}}} -> r != 0 and c != 0 and abs(r) != abs(c)
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
    |> Matrix.update(:one, :a, fn tile -> %{tile | piece: {:some, pieces.black.rook}} end)
    |> Matrix.update(:one, :b, fn tile -> %{tile | piece: {:some, pieces.black.bishop}} end)
    |> Matrix.update(:one, :c, fn tile -> %{tile | piece: {:some, pieces.black.knight}} end)
    |> Matrix.update(:one, :d, fn tile -> %{tile | piece: {:some, pieces.black.queen}} end)
    |> Matrix.update(:one, :e, fn tile -> %{tile | piece: {:some, pieces.black.king}} end)
    |> Matrix.update(:one, :f, fn tile -> %{tile | piece: {:some, pieces.black.knight}} end)
    |> Matrix.update(:one, :g, fn tile -> %{tile | piece: {:some, pieces.black.bishop}} end)
    |> Matrix.update(:one, :h, fn tile -> %{tile | piece: {:some, pieces.black.rook}} end)
    |> Matrix.update(:two, :a, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :b, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :c, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :d, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :e, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :f, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :g, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:two, :h, fn tile -> %{tile | piece: {:some, pieces.black.pawn}} end)
    |> Matrix.update(:seven, :a, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :b, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :c, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :d, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :e, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :f, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :g, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:seven, :h, fn tile -> %{tile | piece: {:some, pieces.white.pawn}} end)
    |> Matrix.update(:eight, :a, fn tile -> %{tile | piece: {:some, pieces.white.rook}} end)
    |> Matrix.update(:eight, :b, fn tile -> %{tile | piece: {:some, pieces.white.bishop}} end)
    |> Matrix.update(:eight, :c, fn tile -> %{tile | piece: {:some, pieces.white.knight}} end)
    |> Matrix.update(:eight, :d, fn tile -> %{tile | piece: {:some, pieces.white.queen}} end)
    |> Matrix.update(:eight, :e, fn tile -> %{tile | piece: {:some, pieces.white.king}} end)
    |> Matrix.update(:eight, :f, fn tile -> %{tile | piece: {:some, pieces.white.knight}} end)
    |> Matrix.update(:eight, :g, fn tile -> %{tile | piece: {:some, pieces.white.bishop}} end)
    |> Matrix.update(:eight, :h, fn tile -> %{tile | piece: {:some, pieces.white.rook}} end)
  end
end
