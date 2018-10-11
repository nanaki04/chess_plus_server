defmodule ChessPlus.Delta.VerifyRules do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Row
  alias ChessPlus.Well.Duel.Column
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Rules
  alias ChessPlus.Option
  alias ChessPlus.Result
  alias ChessPlus.Delta.SimulateRules
  alias ChessPlus.Logger.RuleLogger
  import ChessPlus.Option, only: [<|>: 2, ~>>: 2]
  alias __MODULE__, as: VerifyRules

  @type color :: Rules.color
  @type duelist_type :: Rules.duelist_type
  @type rule :: Rules.rule
  @type clause :: Rules.clause
  @type condition :: Rules.condition
  @type conditions :: Rules.conditions
  @type operator :: Rules.operator
  @type piece :: Duel.piece
  @type pieces :: Duel.pieces
  @type duel :: Duel.duel
  @type coordinate :: Duel.coordinate

  @type option :: {:is_simulation, boolean}
  @type options :: [option]

  @type condition_result :: {:conditional, boolean}
    | {:numeric, number}
    | {:ignore_operator, boolean}

  @type t :: %VerifyRules{
    rule: rule,
    piece: Option.option,
    duelist: Option.option,
    duel: duel,
    is_simulation: boolean
  }

  defstruct rule: nil,
    piece: :none,
    duelist: :none,
    duel: %Duel{},
    is_simulation: false

  @spec verify_rules([rule], Option.option, duel) :: [rule]
  def verify_rules(rules, piece, duel), do: verify_rules(rules, piece, duel, [])

  @spec verify_rules([rule], Option.option, duel, options | color | Option.option) :: [rule]
  def verify_rules(rules, {:some, {_, %{color: color}}} = piece, duel, options) when is_list(options) do
    verify_rules(rules, piece, duel, {:some, color}, options)
  end

  def verify_rules(rules, :none, duel, options) when is_list(options), do: verify_rules(rules, :none, duel, :none, options)

  def verify_rules(rules, piece, duel, color), do: verify_rules(rules, piece, duel, color, [])

  @spec verify_rules([rule], Option.option, duel, color | Option.option, options) :: [rule]
  def verify_rules(rules, piece, duel, :white, options), do: verify_rules(rules, piece, duel, {:some, :white}, options)
  def verify_rules(rules, piece, duel, :black, options), do: verify_rules(rules, piece, duel, {:some, :black}, options)
  def verify_rules(rules, piece, duel, duelist_color, options) when is_list(options) do
    Enum.filter(rules, fn rule -> verify_rule(%VerifyRules{
      rule: rule,
      piece: piece,
      duelist: duelist_color,
      duel: duel,
      is_simulation: Keyword.get(options, :is_simulation, false)
    }) end)
  end

  @spec can_conquer?(coordinate, Option.option | pieces, duel, options) :: boolean
  def can_conquer?(coordinate, piece, duel), do: can_conquer?(coordinate, piece, duel, [])

  def can_conquer?(coordinate, {:some, piece}, duel, options) do
    can_conquer?(coordinate, piece, duel, options)
  end

  def can_conquer?(_, :none, _, _), do: false

  def can_conquer?(coordinate, piece, duel, options) do
    Duel.find_rules_targetting_coord(duel, coordinate, piece)
    |> Enum.filter(fn
      {:conquer, _} -> true
      _ -> false
    end)
    |> verify_rules({:some, piece}, duel, options)
    |> length()
    |> (&(&1 > 0)).()
  end

  @spec can_any_conquer?(coordinate, [pieces], duel, options) :: boolean
  def can_any_conquer?(coordinate, pieces, duel, options) do
    Enum.reduce(pieces, false, fn
      _, true -> true
      piece, false -> can_conquer?(coordinate, piece, duel, options)
    end)
  end

  @spec can_conquer_black_king?(duel, options) :: boolean
  def can_conquer_black_king?(duel, options \\ []) do
    opponent_pieces = Piece.find_by_color(duel, :white)

    (Piece.find_black_king(duel)
    ~>> fn king -> Piece.find_piece_coordinate(duel, king) end
    <|> fn coord -> can_any_conquer?(coord, opponent_pieces, duel, options) end)
    |> Option.or_else(false)
  end

  @spec can_conquer_white_king?(duel, options) :: boolean
  def can_conquer_white_king?(duel, options \\ []) do
    opponent_pieces = Piece.find_by_color(duel, :black)

    (Piece.find_white_king(duel)
    ~>> fn king -> Piece.find_piece_coordinate(duel, king) end
    <|> fn coord -> can_any_conquer?(coord, opponent_pieces, duel, options) end)
    |> Option.or_else(false)
  end

  @spec can_move?(duel, piece | Option.option) :: boolean
  def can_move?(_, :none), do: false
  def can_move?(duel, {:some, piece}), do: can_move?(duel, piece)
  def can_move?(duel, piece) do
    Enum.reduce([:move, :conquer, :move_combo], false, fn
      _, true ->
        true
      rule_type, false ->
        Duel.fetch_piece_rules(duel, piece, rule_type)
        |> Enum.reduce(false, fn
          _, true -> true
          rule, false -> (verify_rules([rule], {:some, piece}, duel) |> length) > 0
        end)
    end)
  end

  def can_white_move?(duel) do
    Piece.find_by_color(duel, :white)
    |> Enum.reduce(false, fn
      _, true -> true
      piece, false -> can_move?(duel, piece)
    end)
  end

  def can_black_move?(duel) do
    Piece.find_by_color(duel, :black)
    |> Enum.reduce(false, fn
      _, true -> true
      piece, false -> can_move?(duel, piece)
    end)
  end

  @spec verify_rule(t) :: boolean
  defp verify_rule(state) do
    verify_conditions(state)
  end

  @spec verify_conditions(t) :: term
  defp verify_conditions(%{rule: {_, %{condition: {:one_of, clauses}}}} = state) when is_list(clauses) do
    Enum.reduce(clauses, false, fn
      clause, false -> verify_clause(state, clause)
      _, true -> true
    end)
  end

  defp verify_conditions(%{rule: {_, %{condition: {:all_of, clauses}}}} = state) when is_list(clauses) do
    Enum.reduce(clauses, true, fn
      clause, true -> verify_clause(state, clause)
      _, false -> false
    end)
  end

  defp verify_conditions(%{rule: {_, %{condition: {_, _} = clause}}} = state), do: verify_clause(state, clause)

  defp verify_conditions(%{rule: {rule_type, %{condition: conditions} = rule_content}} = state) do
    Enum.reduce(conditions, true, fn
      condition, true -> verify_conditions(%VerifyRules{state | rule: {rule_type, %{rule_content | condition: condition}}})
      _, false -> false
    end)
  end

  defp verify_conditions(_), do: true

  @spec verify_clause(t, clause) :: boolean
  defp verify_clause(state, clause) do
    RuleLogger.log(state, clause, fn state, {operator, condition} ->
      verify(state, condition)
      |> apply_operator(operator)
    end)
  end

  @spec verify(t, condition) :: condition_result
  defp verify(_, :always), do: {:conditional, true}

  defp verify(%{piece: {:some, {_, %{move_count: move_count}}}}, :move_count), do: {:numeric, move_count}

  defp verify(%{duel: duel, piece: {:some, piece}, rule: rule}, :target_move_count) do
    Duel.find_rule_target(duel, rule, {:some, piece})
    |> Option.map(fn %{move_count: move_count} -> {:numeric, move_count} end)
    |> Option.or_else({:ignore_operator, false})
  end

  defp verify(%{duel: duel, piece: {:some, piece}}, {:row, row_number}) do
    Piece.find_piece_coordinate(duel, piece)
    |> Option.map(fn {row, _} -> {:conditional, Row.to_num(row) == {:ok, row_number}} end)
    |> Option.or_else({:conditional, false})
  end

  defp verify(%{duel: duel, piece: {:some, piece}}, {:column, column_number}) do
    Piece.find_piece_coordinate(duel, piece)
    |> Option.map(fn {column, _} -> {:conditional, Column.to_num(column) == {:ok, column_number}} end)
    |> Option.or_else({:conditional, false})
  end

  defp verify(%{is_simulation: true}, :exposes_king) do
    {:ignore_operator, true}
  end

  defp verify(%{piece: {:some, {_, %{color: :white}}}} = state, :exposes_king) do
    case SimulateRules.simulate_rule(state.duel, state.rule, state.piece) do
      {:ok, duel} ->
        {:conditional, can_conquer_white_king?(duel, is_simulation: true)}
      {:error, _} ->
        {:ignore_operator, false}
    end
  end

  defp verify(%{piece: {:some, {_, %{color: :black}}}} = state, :exposes_king) do
    case SimulateRules.simulate_rule(state.duel, state.rule, state.piece) do
      {:ok, duel} ->
        {:conditional, can_conquer_black_king?(duel, is_simulation: true)}
      {:error, _} ->
        {:ignore_operator, false}
    end
  end

  defp verify(%{duelist: {:some, :white}, duel: duel}, :exposes_king) do
    {:conditional, can_conquer_white_king?(duel, is_simulation: true)}
  end

  defp verify(%{duelist: {:some, :black}, duel: duel}, :exposes_king) do
    {:conditional, can_conquer_black_king?(duel, is_simulation: true)}
  end

  defp verify(%{piece: {:some, piece}, rule: {_, %{offset: {x, y}}}, duel: duel}, :path_blocked) do
    (Duel.Piece.find_piece_coordinate(duel, piece)
    <|> (&Duel.Coordinate.to_num/1)
    ~>> (&Option.from_result/1)
    <|> fn {origin_x, origin_y} ->
      sign_x = if x < 0, do: -1, else: 1
      sign_y = if y < 0, do: -1, else: 1
      abs_x = abs(x)
      abs_y = abs(y)
      steps = max(abs_x, abs_y) - 1

      factor_x = if steps == 0, do: 0, else: (abs_x - 1) / steps |> max(0)
      factor_y = if steps == 0, do: 0, else: (abs_y - 1) / steps |> max(0)

      if steps == 0, do: {:conditional, false}, else: 1..steps
      |> Enum.reduce(false, fn
        step, false ->
          {factor_x * step, factor_y * step}
          |> (fn {x, y} -> {round(x), round(y)} end).()
          |> (fn {x, y} -> {sign_x * x, sign_y * y} end).()
          |> (fn {x, y} -> {origin_x + x, origin_y + y} end).()
          |> Duel.Coordinate.from_num()
          |> Result.map(fn coord -> Duel.fetch_piece(duel, coord) end)
          |> Result.or_else(:none)
          |> Option.to_bool()
        _, true ->
          true
      end)
      |> (&{:conditional, &1}).()
    end)
    |> Option.or_else({:conditional, false})
  end
  defp verify(_, :path_blocked), do: {:ignore_operator, true}

  defp verify(%{piece: :none}, {:occupied_by, _}), do: {:ignore_operator, false}
  defp verify(%{piece: {:some, {_, %{color: color}}}} = state, {:occupied_by, duelist_type}) do
    (Duel.find_rule_target_coord(state.duel, state.rule, state.piece)
                                 #~>> (&Option.from_result/1)
    ~>> fn coord -> Duel.fetch_piece(state.duel, coord) end
    <|> fn
      {_, %{color: occupant_color}} ->
        case duelist_type do
          :self -> {:conditional, color == occupant_color}
          :other -> {:conditional, color != occupant_color}
          :any -> {:conditional, true}
          _ -> {:conditional, false}
        end
      _ ->
        {:conditional, false}
    end)
    |> Option.or_else({:conditional, false})
  end
  defp verify(_, {:occupied_by, _}), do: {:ignore_operator, false}

  defp verify(_, :conquerable) do
    # TODO
    {:ignore_operator, true}
  end

  defp verify(%{duelist: {:some, :white}} = state, :movable) do
    {:conditional, can_white_move?(state.duel)}
  end

  defp verify(%{duelist: {:some, :black}} = state, :movable) do
    {:conditional, can_black_move?(state.duel)}
  end

  defp verify(_, :defendable) do
    # TODO
    {:ignore_operator, true}
  end

  defp verify(%{duel: duel}, {:remaining_piece_types, piece_types}) do
    {:conditional, Piece.find_piece_types(duel) == piece_types}
  end

  defp verify(%{duel: duel, piece: piece, rule: rule}, {:other_piece_type, type}) do
    Duel.find_rule_target(duel, rule, piece)
    |> Option.map(fn
      {^type, _} -> {:conditional, true}
      _ -> {:conditional, false}
    end)
    |> Option.or_else({:conditional, false})
  end

  # TODO to make dialyzer happy
  defp verify(_, _), do: {:numeric, 0}

  @spec apply_operator(condition_result, operator) :: boolean
  defp apply_operator({:conditional, conditional}, :is), do: conditional
  defp apply_operator({:conditional, conditional}, :not), do: not conditional
  defp apply_operator({:numeric, num}, {:equals, exp}), do: num == exp
  defp apply_operator({:numeric, num}, {:greater_than, comp}), do: num > comp
  defp apply_operator({:numeric, num}, {:smaller_than, comp}), do: num < comp
  defp apply_operator({:ignore_operator, result}, _), do: result
  defp apply_operator(_, _), do: false
end
