defmodule ChessPlus.Delta.VerifyRules do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Rules
  alias ChessPlus.Option
  alias ChessPlus.Delta.SimulateRules
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
    duel: duel,
    is_simulation: boolean
  }

  defstruct rule: nil,
    piece: :none,
    duel: %Duel{},
    is_simulation: false

  @spec verify_rules([rule], Option.option, duel, options) :: [rule]
  def verify_rules(rules, piece, duel, options \\ []) do
    Enum.filter(rules, fn rule -> verify_rule(%VerifyRules{
      rule: rule,
      piece: piece,
      duel: duel,
      is_simulation: Keyword.get(options, :is_simulation, false)
    }) end)
  end

  @spec can_conquer(coordinate, Option.option | pieces, duel, options) :: boolean
  def can_conquer(coordinate, piece, duel), do: can_conquer(coordinate, piece, duel, [])

  def can_conquer(coordinate, {:some, piece}, duel, options) do
    can_conquer(coordinate, piece, duel, options)
  end

  def can_conquer(_, :none, _, _, _), do: false

  def can_conquer(coordinate, piece, duel, options) do
    Duel.find_rules_targetting_coord(duel, coordinate, piece)
    |> Enum.filter(fn
      {:conquer, _} -> true
      _ -> false
    end)
    |> verify_rules({:some, piece}, duel, options)
    |> length()
    |> (&(&1 > 0)).()
  end

  @spec can_any_conquer(coordinate, [pieces], duel, options) :: boolean
  def can_any_conquer(coordinate, pieces, duel, options) do
    Enum.reduce(pieces, false, fn
      _, true -> true
      piece, false -> can_conquer(coordinate, piece, duel, options)
    end)
  end

  @spec can_conquer_black_king(duel, options) :: boolean
  def can_conquer_black_king(duel, options \\ []) do
    opponent_pieces = Piece.find_by_color(duel, :white)

    (Piece.find_black_king(duel)
    ~>> fn king -> Piece.find_piece_coordinate(duel, king) end
    <|> fn coord -> can_any_conquer(coord, opponent_pieces, duel, options) end)
    |> Option.or_else(false)
  end

  @spec can_conquer_white_king(duel, options) :: boolean
  def can_conquer_white_king(duel, options \\ []) do
    opponent_pieces = Piece.find_by_color(duel, :black)

    (Piece.find_white_king(duel)
    ~>> fn king -> Piece.find_piece_coordinate(duel, king) end
    <|> fn coord -> can_any_conquer(coord, opponent_pieces, duel, options) end)
    |> Option.or_else(false)
  end

  @spec verify_rule(t) :: boolean
  defp verify_rule(state) do
    verify_conditions(state)
  end

  @spec verify_conditions(t) :: term
  defp verify_conditions(%{rule: {_, %{condition: {_, _} = clause}}} = state), do: verify_clause(state, clause)

  defp verify_conditions(%{rule: {_, %{condition: {:one_of, clauses}}}} = state) do
    Enum.reduce(clauses, false, fn
      clause, false -> verify_clause(state, clause)
      _, true -> true
    end)
  end

  defp verify_conditions(%{rule: {_, %{condition: {:all_of, clauses}}}} = state) do
    Enum.reduce(clauses, true, fn
      clause, true -> verify_clause(state, clause)
      _, false -> false
    end)
  end

  defp verify_conditions(%{rule: {rule_type, %{condition: conditions} = rule_content}} = state) do
    Enum.reduce(conditions, true, fn
      condition, true -> verify_conditions(%VerifyRules{state | rule: {rule_type, %{rule_content | condition: condition}}})
      _, false -> false
    end)
  end

  defp verify_conditions(_), do: true

  @spec verify_clause(t, clause) :: boolean
  defp verify_clause(state, {operator, condition}) do
    verify(state, condition)
    |> apply_operator(operator)
  end

  @spec verify(t, condition) :: condition_result
  defp verify(_, :always), do: {:conditional, true}
  defp verify(%{piece: {:some, {_, %{move_count: move_count}}}}), do: {:numeric, move_count}

  defp verify(%{is_simulation: true}, :exposes_king) do
    {:ignore_operator, true}
  end

  defp verify(%{piece: {:some, {_, %{color: :white}}}} = state, :exposes_king) do
    duel = SimulateRules.simulate_rule(state.duel, state.rule, state.piece)
    {:conditional, can_conquer_white_king(duel, is_simulation: true)}
  end

  defp verify(%{piece: {:some, {_, %{color: :black}}}} = state, :exposes_king) do
    duel = SimulateRules.simulate_rule(state.duel, state.rule, state.piece)
    {:conditional, can_conquer_black_king(duel, is_simulation: true)}
  end

  defp verify(state, :path_blocked) do
    # TODO
    {:ignore_operator, true}
  end

  defp verify(%{piece: :none}, {:occupied_by, _}), do: {:ignore_operator, false}
  defp verify(%{piece: {_, %{color: color}}} = state, {:occupied_by, duelist_type}) do
    (Duel.find_rule_target_coord(state.duel, state.rule, state.piece)
    <|> fn coord -> Duel.fetch_piece(state.duel, coord) end
    <|> fn
      {:some, %{color: occupant_color}} ->
        case duelist_type do
          :self -> {:conditional, color == occupant_color}
          :other -> {:conditional, color != occupant_color}
          :any -> {:conditional, true}
          _ -> {:conditional, false}
        end
      _ -> {:conditional, false}
    end)
    |> Option.or_else({:conditional, false})
  end

  defp verify(state, :conquerable) do
    # TODO
    {:ignore_operator, true}
  end

  defp verify(state, :movable) do
    # TODO
    {:ignore_operator, true}
  end

  defp verify(state, :defendable) do
    # TODO
    {:ignore_operator, true}
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
