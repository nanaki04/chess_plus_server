defmodule ChessPlus.Well.Rules do

  @vsn "0"

  @type piece_type :: ChessPlus.Well.Duel.piece_type

  @type color :: :black
    | :white

  @type duelist_type :: :any
    | :self
    | :other
    | {:player, color}

  @type condition :: :always
    | :move_count
    | :target_move_count
    | :exposes_king
    | :path_blocked
    | {:occupied_by, duelist_type}
    | :conquerable
    | :movable
    | :defendable
    | {:other_piece_type, piece_type}
    | {:other_owner, duelist_type}
    | :exposed_while_moving
    | {:row, number}
    | {:column, number}
    | {:remaining_piece_types, [piece_type]}

  @type operator :: :is
    | :not
    | {:equals, number}
    | {:greater_than, number}
    | {:smaller_than, number}

  @type clause :: {operator, condition}

  @type conditions :: clause
    | {:one_of, [clause]}
    | {:all_of, [clause]}
    | [conditions]

  @type move :: %{
    condition: conditions,
    offset: {number, number}
  }

  @type conquer :: %{
    condition: conditions,
    offset: {number, number}
  }

  @type move_combo :: %{
    condition: conditions,
    other: {number, number},
    my_movement: {number, number},
    other_movement: {number, number}
  }

  @type conquer_combo :: %{
    condition: conditions,
    target_offset: {number, number},
    my_movement: {number, number}
  }

  @type promote :: %{
    condition: conditions,
    ranks: number
  }

  @type defeat :: %{
    condition: conditions
  }

  @type remise :: %{
    condition: conditions
  }

  @type add_buff_on_move :: %{
    condition: conditions,
    target_offset: {number, number},
    buff_id: number
  }

  @type rule :: {:move, move}
    | {:conquer, conquer}
    | {:move_combo, move_combo}
    | {:conquer_combo, conquer_combo}
    | {:promote, promote}
    | {:defeat, defeat}
    | {:remise, remise}
    | {:add_buff_on_move, add_buff_on_move}

  @type rules :: %{optional(number) => rule}

  @default_move_conditions {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}

  @default_conquer_conditions {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_move({1, 1})
    {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}}
  """
  @spec new_move({number, number}, conditions) :: rule
  def new_move(offset, condition \\ @default_move_conditions) do
    {:move, %{
      condition: condition,
      offset: offset
    }}
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_conquer({1, 1})
    {:conquer, %{condition: {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}, offset: {1, 1}}}
  """
  @spec new_conquer({number, number}, conditions) :: rule
  def new_conquer(offset, condition \\ @default_conquer_conditions) do
    {:conquer, %{
      condition: condition,
      offset: offset
    }}
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> gen_moves({1, 1}, 2)
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {3, 3}}}
    ]
  """
  @spec gen_moves({number, number}, number, conditions) :: [rule]
  def gen_moves({r, c}, repeat, condition \\ @default_move_conditions) do
    1..repeat
    |> Enum.map(fn x -> {r * x, c * x} end)
    |> Enum.map(fn offset -> new_move(offset, condition) end)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> gen_conquers({-1, 1}, 2)
    [
      {:conquer, %{condition: {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}, offset: {-1, 1}}},
      {:conquer, %{condition: {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}, offset: {0, 2}}},
      {:conquer, %{condition: {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}, offset: {1, 3}}}
    ]
  """
  @spec gen_conquers({number, number}, number, conditions) :: [rule]
  def gen_conquers({r, c}, repeat, condition \\ @default_conquer_conditions) do
    1..repeat
    |> Enum.map(fn x -> {r * x, c * x} end)
    |> Enum.map(fn ofs -> new_conquer(ofs, condition) end)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_move({1, 1})
    ...> |> mirror_move_horizontal()
    {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, -1}}}
  """
  @spec mirror_move_horizontal(rule) :: rule
  def mirror_move_horizontal({:move, %{offset: {r, c}} = move}) do
    {:move, %{move | offset: {r, -c}}}
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> gen_and_mirror_moves_horizontal({1, 1}, 2)
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, -2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {3, -3}}}
    ]
  """
  @spec gen_and_mirror_moves_horizontal({number, number}, number, conditions) :: [rule]
  def gen_and_mirror_moves_horizontal(coordinates, repeat, condition \\ @default_move_conditions) do
    gen_moves(coordinates, repeat, condition)
    |> Enum.map(&mirror_move_horizontal/1)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_move({1, 1})
    ...> |> mirror_move_vertical()
    {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, 1}}}
  """
  @spec mirror_move_vertical(rule) :: rule
  def mirror_move_vertical({:move, %{offset: {r, c}} = move}) do
    {:move, %{move | offset: {-r, c}}}
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> gen_and_mirror_moves_vertical({1, 1}, 2)
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-3, 3}}}
    ]
  """
  @spec gen_and_mirror_moves_vertical({number, number}, number, conditions) :: [rule]
  def gen_and_mirror_moves_vertical(coordinates, repeat, condition \\ @default_move_conditions) do
    gen_moves(coordinates, repeat, condition)
    |> Enum.map(&mirror_move_vertical/1)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_move({1, 1})
    ...> |> quadra_mirror_move()
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, -1}}}
    ]

    ...> new_move({0, 1})
    ...> |> quadra_mirror_move()
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {0, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {0, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {0, -1}}},
      %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {0, -1}}
    ]
  """
  @spec quadra_mirror_move(rule) :: [rule]
  def quadra_mirror_move(move) do
    move
    |> mirror_move_horizontal()
    |> (&[move, &1]).()
    |> Enum.flat_map(fn m -> [m, mirror_move_vertical(m)] end)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> [new_move({1, 1}), new_move({2, 2})]
    ...> |> quadra_mirror_moves()
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, -2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-2, -2}}}
    ]
  """
  @spec quadra_mirror_moves([rule]) :: [rule]
  def quadra_mirror_moves(moves) do
    moves
    |> Enum.flat_map(&quadra_mirror_move/1)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> new_conquer({1, 1})
    ...> |> mirror_conquer_horizontal()
    {:conquer, %{condition: {:all_of, [{:is, {:occupied_by, :other}}, {:not, :path_blocked}, {:not, :exposes_king}]}, offset: {1, -1}}}
  """
  @spec mirror_conquer_horizontal(rule) :: rule
  def mirror_conquer_horizontal({:conquer, %{offset: {r, c}} = conquer}) do
    {:conquer, %{conquer | offset: {r, -c}}}
  end

  @spec gen_and_mirror_conquers_horizontal({number, number}, number, conditions) :: [rule]
  def gen_and_mirror_conquers_horizontal(coordinates, repeat, condition \\ @default_conquer_conditions) do
    gen_conquers(coordinates, repeat, condition)
    |> Enum.map(&mirror_conquer_horizontal/1)
  end

  @spec mirror_conquer_vertical(rule) :: rule
  def mirror_conquer_vertical({:conquer, %{offset: {r, c}} = conquer}) do
    {:conquer, %{conquer | offset: {-r, c}}}
  end

  @spec gen_and_mirror_conquers_vertical({number, number}, number, conditions) :: [rule]
  def gen_and_mirror_conquers_vertical(coordinates, repeat, condition \\ @default_conquer_conditions) do
    gen_conquers(coordinates, repeat, condition)
    |> Enum.map(&mirror_conquer_vertical/1)
  end

  @spec quadra_mirror_conquer(rule) :: [rule]
  def quadra_mirror_conquer(conquer) do
    conquer
    |> mirror_conquer_horizontal()
    |> (&[conquer, &1]).()
    |> Enum.flat_map(fn m -> [m, mirror_conquer_vertical(m)] end)
  end

  @spec quadra_mirror_conquers([rule]) :: [rule]
  def quadra_mirror_conquers(conquers) do
    conquers
    |> Enum.flat_map(&quadra_mirror_conquer/1)
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Well.Rules
    ...> gen_and_quadra_mirror_moves({1, 1}, 1)
    [
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, 1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-1, -1}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-2, 2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, -2}}},
      {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {-2, -2}}}
    ]
  """
  @spec gen_and_quadra_mirror_moves({number, number}, number, conditions) :: [rule]
  def gen_and_quadra_mirror_moves(offset, repeat, condition \\ @default_move_conditions) do
    gen_moves(offset, repeat, condition)
    |> quadra_mirror_moves()
  end

  @spec gen_and_quadra_mirror_conquers({number, number}, number, conditions) :: [rule]
  def gen_and_quadra_mirror_conquers(offset, repeat, condition \\ @default_conquer_conditions) do
    gen_conquers(offset, repeat, condition)
    |> quadra_mirror_conquers()
  end

  @doc """

  ## Examples
    iex> import ChessPlus.Well.Rules
    ...> gen_moves({1, 1}, 2)
    ...> |> to_map()
    %{
      0 => {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {1, 1}}},
      1 => {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {2, 2}}},
      2 => {:move, %{condition: {:all_of, [{:not, :path_blocked}, {:not, {:occupied_by, :any}}, {:not, :exposes_king}]}, offset: {3, 3}}}
    }
    ...> to_map([{:remise, %{conditions: {:not, :movable}}}])
    %{
      0 => {:remise, %{conditions: {:not, :movable}}}
    }
  """
  @spec to_map([rule]) :: rules
  def to_map(rules) do
    rules
    |> Enum.with_index()
    |> Enum.map(fn {rule, index} -> {index, rule} end)
    |> Enum.into(%{})
  end

  @doc """

  ## Examples
    iex> import ChessPlus.Well.Rules
    ...> gen_and_quadra_mirror_moves({1, 1}, 1)
    ...> |> to_map()
    ...> |> find_rule_ids(fn
    ...>   {:move, %{offset: {-1, 1}}} -> true
    ...>   {:move, %{offset: {2, 2}}} -> true
    ...>   _ -> false
    ...> end)
    [1, 4]
  """
  @spec find_rule_ids(rules, (rule -> boolean)) :: [number]
  def find_rule_ids(rules, predicate) do
    Enum.filter(rules, fn {_, rule} -> predicate.(rule) end)
    |> Enum.map(&elem(&1, 0))
  end

  @spec find_rules(rules, [number] | (rule -> boolean)) :: [rule]
  def find_rules(rules, ids) when is_list(ids) do
    Enum.reduce(ids, [], fn id, acc ->
      case Map.fetch(rules, id) do
        {:ok, rule} -> [rule | acc]
        _ -> acc
      end
    end)
  end

  def find_rules(rules, predicate) do
    Enum.filter(rules, fn {_, rule} -> predicate.(rule) end)
    |> Enum.map(&elem(&1, 1))
  end

  @spec find_rules(rules, [number], atom) :: [rule]
  def find_rules(rules, ids, rule_type) do
    find_rules(rules, ids)
    |> Enum.filter(fn {type, _} -> type == rule_type end)
  end

  @spec filter_on_piece_moved_rules([rule]) :: [rule]
  def filter_on_piece_moved_rules(rules) do
    ChessPlus.Logger.log(rules)
    Enum.filter(rules, fn
      {:promote, _} -> true
      {:add_buff_on_move, _} -> true
      _ -> false
    end)
  end

  @spec sort_rules([rule]) :: [rule]
  def sort_rules(rules) do
    Enum.sort(rules, fn
      {:move_combo, _}, _ -> true
      _, {:move_combo, _} -> false
      {:conquer_combo, _}, _ -> true
      _, {:conquer_combo, _} -> false
      {:conquer, _}, _ -> true
      _, {:conquer, _} -> false
      {:move, _}, _ -> true
      _, {:move, _} -> false
      {:promote, _}, _ -> true
      _, {:promote, _} -> false
      {:add_buff_on_move, _}, _ -> true
      {_, :add_buff_on_move}, _ -> false
      {:defeat, _}, _ -> true
      _, {:defeat, _} -> false
      {:remise, _}, _ -> true
    end)
  end
end
