defmodule ChessPlus.Rock.Duel.Classic do
  alias ChessPlus.Well.Rules
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Row
  alias ChessPlus.Well.Duel.Column
  alias ChessPlus.Result
  alias ChessPlus.Matrix
  import ChessPlus.Result, only: [<|>: 2, <~>: 2]

  @behaviour ChessPlus.Rock

  @en_passant_buff_black_id 0
  @en_passant_buff_white_id 1

  @impl(ChessPlus.Rock)
  def retrieve() do
    rules = build_rules()
    pieces = build_piece_templates(rules)
    buffs = build_buffs(rules)
    build_tiles()
    <|> fn tiles -> place_pieces(tiles, pieces) end
    <|> fn tiles -> %Duel{
      duelists: [],
      board: %{ tiles: tiles },
      rules: rules,
      piece_templates: pieces,
      win_conditions: Rules.find_rules(rules, fn 
        {:defeat, _} -> true
        {:remise, _} -> true
        _ -> false
      end),
      duel_state: {:turn, :white},
      buffs: %{
        active_buffs: [],
        buffs: buffs
      }
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
    ++ Rules.gen_conquers({1, 0}, 7)
    ++ Rules.gen_conquers({-1, 0}, 7)
    ++ Rules.gen_conquers({0, 1}, 7)
    ++ Rules.gen_conquers({0, -1}, 7)
    # angle conquers
    ++ Rules.gen_and_quadra_mirror_conquers({1, 1}, 7)
    # knight conquers
    ++ (Enum.map([{1, 2}, {2, 1}], &Rules.new_conquer(&1, {:all_of, [{:is, {:occupied_by, :other}}, {:not, :exposes_king}]}))
      |> Rules.quadra_mirror_conquers())

    # rochades
    ++ [{:move_combo, %{
      other: {0, 3},
      my_movement: {0, 2},
      other_movement: {0, -2},
      condition: {
        :all_of, [
          {:not, :path_blocked},
          {:is, {:other_piece_type, :rook}},
          {:is, {:other_owner, :self}},
          {{:equals, 0}, :move_count},
          {:not, :exposed_while_moving},
          {:not, {:occupied_by, :any}},
        ]
      }
    }},

    {:move_combo, %{
      other: {0, -4},
      my_movement: {0, -2},
      other_movement: {0, 3},
      condition: {
        :all_of, [
          {:not, :path_blocked},
          {:is, {:other_piece_type, :rook}},
          {:is, {:other_owner, :self}},
          {{:equals, 0}, :move_count},
          {:not, :exposed_while_moving},
          {:not, {:occupied_by, :any}},
        ]
      }
    }}]

    # En Passant
    ++ [{:conquer_combo, %{
      target_offset: {0, 1},
      my_movement: {1, 1},
      condition: {
        :all_of, [
          {{:equals, 1}, :target_move_count},
          {:is, {:other_piece_type, :pawn}},
          {:is, {:other_owner, :other}}
        ]
      }
    }},

    {:conquer_combo, %{
      target_offset: {0, -1},
      my_movement: {1, -1},
      condition: {
        :all_of, [
          {{:equals, 1}, :target_move_count},
          {:is, {:other_piece_type, :pawn}},
          {:is, {:other_owner, :other}}
        ]
      }
    }},

    {:conquer_combo, %{
      target_offset: {0, 1},
      my_movement: {-1, 1},
      condition: {
        :all_of, [
          {{:equals, 1}, :target_move_count},
          {:is, {:other_piece_type, :pawn}},
          {:is, {:other_owner, :other}}
        ]
      }
    }},

    {:conquer_combo, %{
      target_offset: {0, -1},
      my_movement: {-1, -1},
      condition: {
        :all_of, [
          {{:equals, 1}, :target_move_count},
          {:is, {:other_piece_type, :pawn}},
          {:is, {:other_owner, :other}}
        ]
      }
    }},

    {:add_buff_on_move, %{
      condition: {
        :all_of, [
          {{:equals, 1}, :move_count},
          {:is, {:other_piece_type, :pawn}}
        ]
      },
      buff_id: @en_passant_buff_black_id,
      target_offset: {0, 1}
    }},

    {:add_buff_on_move, %{
      condition: {
        :all_of, [
          {{:equals, 1}, :move_count},
          {:is, {:other_piece_type, :pawn}}
        ]
      },
      buff_id: @en_passant_buff_black_id,
      target_offset: {0, -1}
    }},

    {:add_buff_on_move, %{
      condition: {
        :all_of, [
          {{:equals, 1}, :move_count},
          {:is, {:other_piece_type, :pawn}}
        ]
      },
      buff_id: @en_passant_buff_white_id,
      target_offset: {0, 1}
    }},

    {:add_buff_on_move, %{
      condition: {
        :all_of, [
          {{:equals, 1}, :move_count},
          {:is, {:other_piece_type, :pawn}}
        ]
      },
      buff_id: @en_passant_buff_white_id,
      target_offset: {0, -1}
    }}]

    # promotions
    ++ [{:promote, %{
      ranks: ChessPlus.Well.Duel.Piece.type_to_rank(:queen) |> Result.or_else(0),
      condition: {:is, {:row, 1}}
    }},

    {:promote, %{
      ranks: ChessPlus.Well.Duel.Piece.type_to_rank(:queen) |> Result.or_else(0),
      condition: {:is, {:row, 8}}
    }}]

    # win conditions
    ++ [{:defeat, %{condition: {:all_of, [{:not, :movable}, {:is, :exposes_king}]}}}]
    ++ [{:remise, %{condition: {:all_of, [{:not, :movable}, {:not, :exposes_king}]}}}]
    ++ [{:remise, %{condition: {:is, {:remaining_piece_types, [:king]}}}}]

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

  @spec build_buffs(Rules.rules) :: [ChessPlus.Well.Duel.buff]
  def build_buffs(rules) do
    black_conquer_combo_rule_ids = Rules.find_rule_ids(rules, fn
      {:conquer_combo, %{my_movement: {1, 1}}} -> true
      {:conquer_combo, %{my_movement: {1, -1}}} -> true
      _ -> false
    end)

    white_conquer_combo_rule_ids = Rules.find_rule_ids(rules, fn
      {:conquer_combo, %{my_movement: {-1, 1}}} -> true
      {:conquer_combo, %{my_movement: {-1, -1}}} -> true
      _ -> false
    end)

    [
      %{
        id: 0,
        duration: {:turn, 1},
        type: {
          :add_rule,
          %{
            rules: white_conquer_combo_rule_ids
          }
        }
      },
      %{
        id: 1,
        duration: {:turn, 1},
        type: {
          :add_rule,
          %{
            rules: black_conquer_combo_rule_ids
          }
        }
      }
    ]
    |> Enum.with_index()
    |> Enum.map(fn {buff, index} -> {index, buff} end)
    |> Enum.into(%{})
  end

  @spec build_piece_templates(Rules.rules) :: term
  def build_piece_templates(rules) do
    en_passant_buff_black_id = @en_passant_buff_black_id
    en_passant_buff_white_id = @en_passant_buff_white_id

    black = %{
      pawn: {:pawn, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}}} -> true
          {:move, %{offset: {1, 0}}} -> true
          {:conquer, %{offset: {1, x}}} -> x == -1 or x == 1
          {:promote, %{condition: {_, {_, 8}}}} -> true
          {:add_buff_on_move, %{buff_id: ^en_passant_buff_black_id}} -> true
          _ -> false
        end)
      }},
      king: {:king, %{
        color: :black,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:conquer, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
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
          {:move, %{offset: {-2, 0}, condition: {:all_of, [{{:equals, 0}, :move_count}, {:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}}} -> true
          {:move, %{offset: {-1, 0}}} -> true
          {:conquer, %{offset: {-1, c}}} -> c == -1 or c == 1
          {:promote, %{condition: {_, {_, 1}}}} -> true
          {:add_buff_on_move, %{buff_id: ^en_passant_buff_white_id}} -> true
          _ -> false
        end)
      }},
      king: {:king, %{
        color: :white,
        rules: Rules.find_rule_ids(rules, fn
          {:move, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
          {:conquer, %{offset: {r, c}}} -> abs(r) < 2 and abs(c) < 2
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
