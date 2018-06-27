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
      board: %{ tiles: tiles },
      rules: rules,
      duel_state: {:turn, :white}
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
    ++ (Enum.map([{1, 2}, {2, 1}], &Rules.new_move(&1, {:all_of, [{:not, {:occupied_by, :any}}, {:not, :exposes_king}]}))
      |> Rules.quadra_mirror_moves())
    # pawn first moves
    ++ [Rules.new_move({2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]})]
    ++ [Rules.new_move({-2, 0}, {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]})]

    # conquers
    # straight conquers
    ++ Rules.gen_and_mirror_conquers_vertical({1, 0}, 7)
    ++ Rules.gen_and_mirror_conquers_horizontal({0, 1}, 7)
    # angle conquers
    ++ Rules.gen_and_quadra_mirror_conquers({1, 1}, 7)
    # knight conquers
    ++ (Enum.map([{1, 2}, {2, 1}], &Rules.new_conquer(&1, {:all_of, [{:is, {:occupied_by, :other}}, {:not, :exposes_king}]}))
      |> Rules.quadra_mirror_conquers())

    # win conditions
    ++ [{:defeat, %{condition: {:all_of, [{:is, :conquerable}, {:not, :defendable}]}}}]
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
      {{:ok, rows}, {:ok, cols}} -> {:ok, Matrix.initialize(rows, cols, %{piece: :none, selected_by: :none, conquerable_by: :none, color: :black})}
      {{:error, err}, {:ok, _}} -> {:error, err}
      {{:ok, _}, {:error, err}} -> {:error, err}
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

  @spec build_piece_templates(Rules.rules) :: term
  def build_piece_templates(rules) do
    black = %{
      pawn: {:pawn, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {1, 0}}} -> true
          {:conquer, %{offset: {1, x}}} -> x == -1 or x == 1
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
          {:move, %{offset: {-2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}]}}} -> true
          {:move, %{offset: {-1, 0}}} -> true
          {:conquer, %{offset: {-1, c}}} -> c == -1 or c == 1
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

  def place_piece({id, pieces}, row, col, {type, parameters}) do
    pieces = Matrix.update(pieces, row, col, fn tile -> %{
      tile
      | piece: {:some, {type, Map.put(parameters, :id, id) |> Map.put(:move_count, 0)}}
    } end)
    {id + 1, pieces}
  end

  def place_pieces(tiles, pieces) do
    {1, tiles}
    |> place_piece(:one, :a, pieces.black.rook)
    |> place_piece(:one, :b, pieces.black.knight)
    |> place_piece(:one, :c, pieces.black.bishop)
    |> place_piece(:one, :d, pieces.black.queen)
    |> place_piece(:one, :e, pieces.black.king)
    |> place_piece(:one, :f, pieces.black.bishop)
    |> place_piece(:one, :g, pieces.black.knight)
    |> place_piece(:one, :h, pieces.black.rook)
    |> place_piece(:two, :a, pieces.black.pawn)
    |> place_piece(:two, :b, pieces.black.pawn)
    |> place_piece(:two, :c, pieces.black.pawn)
    |> place_piece(:two, :d, pieces.black.pawn)
    |> place_piece(:two, :e, pieces.black.pawn)
    |> place_piece(:two, :f, pieces.black.pawn)
    |> place_piece(:two, :g, pieces.black.pawn)
    |> place_piece(:two, :h, pieces.black.pawn)
    |> place_piece(:seven, :a, pieces.white.pawn)
    |> place_piece(:seven, :b, pieces.white.pawn)
    |> place_piece(:seven, :c, pieces.white.pawn)
    |> place_piece(:seven, :d, pieces.white.pawn)
    |> place_piece(:seven, :e, pieces.white.pawn)
    |> place_piece(:seven, :f, pieces.white.pawn)
    |> place_piece(:seven, :g, pieces.white.pawn)
    |> place_piece(:seven, :h, pieces.white.pawn)
    |> place_piece(:eight, :a, pieces.white.rook)
    |> place_piece(:eight, :b, pieces.white.knight)
    |> place_piece(:eight, :c, pieces.white.bishop)
    |> place_piece(:eight, :d, pieces.white.queen)
    |> place_piece(:eight, :e, pieces.white.king)
    |> place_piece(:eight, :f, pieces.white.bishop)
    |> place_piece(:eight, :g, pieces.white.knight)
    |> place_piece(:eight, :h, pieces.white.rook)
    |> (fn {_, tiles} -> tiles end).()
  end
end
