defmodule ChessPlus.Dto.Well do
  alias ChessPlus.Result
  alias ChessPlus.Well.Rules
  alias ChessPlus.Well.Duel
  import ChessPlus.Result, only: [<|>: 2, <~>: 2, ~>>: 2]

  defmodule Color do
    @type dto :: term
    @spec export(Rules.color) :: Result.result
    def export(:black), do: "Black"
    def export(:white), do: "White"
    def export(_), do: {:error, "Failed to export Color"}

    @spec imprt(dto) :: Result.result
    def imprt("Black"), do: {:ok, :black}
    def imprt("White"), do: {:ok, :white}
    def imprt(_), do: {:error, "Failed to import Color"}
  end

  defmodule Row do
    @type dto :: term
    @spec export(Duel.row) :: Result.result
    def export(row), do: ChessPlus.Well.Duel.Row.to_num(row)

    @spec imprt(dto) :: Result.result
    def imprt(row), do: ChessPlus.Well.Duel.Row.from_num(row)
  end

  defmodule Column do
    @type dto :: term
    @spec export(Duel.column) :: Result.result
    def export(:a), do: {:ok, "A"}
    def export(:b), do: {:ok, "B"}
    def export(:c), do: {:ok, "C"}
    def export(:d), do: {:ok, "D"}
    def export(:e), do: {:ok, "E"}
    def export(:f), do: {:ok, "F"}
    def export(:g), do: {:ok, "G"}
    def export(:h), do: {:ok, "H"}
    def export(_), do: {:error, "Failed to export Column"}

    @spec imprt(dto) :: Result.result
    def imprt("A"), do: {:ok, :a}
    def imprt("B"), do: {:ok, :b}
    def imprt("C"), do: {:ok, :c}
    def imprt("D"), do: {:ok, :d}
    def imprt("E"), do: {:ok, :e}
    def imprt("F"), do: {:ok, :f}
    def imprt("G"), do: {:ok, :g}
    def imprt("H"), do: {:ok, :h}
    def imprt(_), do: {:error, "Failed to import Column"}
  end

  defmodule Coordinate do
    @type dto :: term
    @spec export(Duel.coordinate) :: Result.result
    def export({r, c}) do
      {:ok, &%{"Row" => &1, "Column" => &2}}
      <~> Row.export(r)
      <~> Column.export(c)
    end
    def export(_), do: {:error, "Failed to export Coordinate"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Row" => row, "Column" => col}) do
      {:ok, &{&1, &2}}
      <~> Row.imprt(row)
      <~> Column.imprt(col)
    end
    def imprt(_), do: {:error, "Failed to import Coordinate"}
  end

  defmodule DuelistType do
    @type dto :: term
    @spec export(Rules.duelist_type) :: Result.result
    def export(:any), do: {:ok, %{"Type" => "Any"}}
    def export(:self), do: {:ok, %{"Type" => "Self"}}
    def export(:other), do: {:ok, %{"Type" => "Other"}}
    def export({:player, color}) do
      Color.export(color)
      <|> fn c -> %{"Type" => "Other", "Player" => c} end
    end
    def export(_), do: {:error, "Failed to export DuelistType"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Any"}), do: {:ok, :any}
    def imprt(%{"Type" => "Self"}), do: {:ok, :self}
    def imprt(%{"Type" => "Other"}), do: {:ok, :other}
    def imprt(%{"Type" => "Player", "Player" => color}) do
      Color.imprt(color)
      <|> fn c -> {:player, c} end
    end
    def imprt(_), do: {:error, "Failed to import DuelistType"}
  end

  defmodule Condition do
    @type dto :: term
    @spec export(Rules.condition) :: Result.result
    def export(:always), do: {:ok, %{"Type" => "Always"}}
    def export(:move_count), do: {:ok, %{"Type" => "MoveCount"}}
    def export(:exposes_king), do: {:ok, %{"Type" => "ExposesKing"}}
    def export(:path_blocked), do: {:ok, %{"Type" => "PathBlocked"}}
    def export({:occupied_by, duelist_type}) do
      DuelistType.export(duelist_type)
      <|> fn d -> %{"Type" => "OccupiedBy", "OccupiedBy" => d} end
    end
    def export(:conquerable), do: {:ok, %{"Type" => "Conquerable"}}
    def export(:movable), do: {:ok, %{"Type" => "Movable"}}
    def export(:defendable), do: {:ok, %{"Type" => "Defendable"}}
    def export(_), do: {:error, "Failed to export Condition"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Always"}), do: {:ok, :always}
    def imprt(%{"Type" => "MoveCount"}), do: {:ok, :move_count}
    def imprt(%{"Type" => "ExposesKing"}), do: {:ok, :exposes_king}
    def imprt(%{"Type" => "PathBlocked"}), do: {:ok, :path_blocked}
    def imprt(%{"Type" => "OccupiedBy", "OccupiedBy" => occupied_by}) do
      DuelistType.imprt(occupied_by)
      <|> fn d -> {:occupied_by, d} end
    end
    def imprt(%{"Type" => "Conquerable"}), do: {:ok, :conquerable}
    def imprt(%{"Type" => "Movable"}), do: {:ok, :movable}
    def imprt(%{"Type" => "Defendable"}), do: {:ok, :defendable}
    def imprt(_), do: {:error, "Failed to import Condition"}
  end

  defmodule Operator do
    @type dto :: term
    @spec export(Rules.operator) :: Result.result
    def export(:is), do: {:ok, %{"Type" => "Is"}}
    def export(:not), do: {:ok, %{"Type" => "Not"}}
    def export({:equals, number}), do: {:ok, %{"Type" => "Equals", "Value" => number}}
    def export({:greater_than, number}), do: {:ok, %{"Type" => "GreaterThan", "Value" => number}}
    def export({:smaller_than, number}), do: {:ok, %{"Type" => "SmallerThan", "Value" => number}}
    def export(_), do: {:error, "Failed to export Operator"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Is"}), do: {:ok, :is}
    def imprt(%{"Type" => "Not"}), do: {:ok, :not}
    def imprt(%{"Type" => "GreaterThan", "Value" => number}), do: {:ok, {:greater_than, number}}
    def imprt(%{"Type" => "SmallerThan", "Value" => number}), do: {:ok, {:smaller_than, number}}
    def imprt(_), do: {:error, "Failed to import Operator"}
  end

  defmodule Clause do
    @type dto :: term
    @spec export(Rules.clause) :: Result.result
    def export({operator, condition}) do
      {:ok, &%{"Operator" => &1, "Condition" => &2}}
      <~> Operator.export(operator)
      <~> Condition.export(condition)
    end
    def export(_), do: {:error, "Failed to export Clause"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Operator" => operator, "Condition" => condition}) do
      {:ok, &{&1, &2}}
      <~> Operator.imprt(operator)
      <~> Condition.imprt(condition)
    end
    def imprt(_), do: {:error, "Failed to import Clause"}
  end

  defmodule Conditions do
    @type dto :: term
    @spec export(Rules.conditions) :: Result.result
    def export({:one_of, clauses}) do
      Enum.map(clauses, &Clause.export/1)
      |> Result.unwrap()
      <|> &%{"Type" => "OneOf", "Clauses" => &1}
    end
    def export({:all_of, clauses}) do
      Enum.map(clauses, &Clause.export/1)
      |> Result.unwrap()
      <|> &%{"Type" => "AllOf", "Clauses" => &1}
    end
    def export(conditions) when is_list(conditions) do
      Enum.map(conditions, &export/1)
      |> Result.unwrap()
      <|> &%{"Type" => "Combination", "Combination" => &1}
    end
    def export(clause) do
      Clause.export(clause)
      <|> &%{"Type" => "Clause", "Clause" => &1}
    end

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "OneOf", "Clauses" => clauses}) do
      Enum.map(clauses, &Clause.imprt/1)
      |> Result.unwrap()
      <|> &{:one_of, &1}
    end
    def imprt(%{"Type" => "AllOf", "Clauses" => clauses}) do
      Enum.map(clauses, &Clause.imprt/1)
      |> Result.unwrap()
      <|> &{:all_of, &1}
    end
    def imprt(%{"Type" => "Combination", "Combination" => combination}) do
      Enum.map(combination, &__MODULE__.imprt/1)
      |> Result.unwrap()
    end
    def imprt(%{"Type" => "Clause", "Clause" => clause}) do
      Clause.imprt(clause)
    end
    def imprt(_), do: {:error, "Failed to import Conditions"}
  end

  defmodule Rule do
    @type dto :: term

    @doc """

      ## Examples
      iex> import ChessPlus.Dto.Well.Rule
      ...> {:move, %{condition: {:one_of, [{:not, :path_blocked}, {:not, :exposes_king}]}, offset: {1, 1}}}
      ...> |> export()
      {:ok, %{
        "Condition" => %{
          "Clauses" => [
            %{
              "Condition" => %{
                "Type" => "PathBlocked"
              },
              "Operator" => %{
                "Type" => "Not"
              }
            },
            %{
              "Condition" => %{
                "Type" => "ExposesKing"
              },
              "Operator" => %{
                "Type" => "Not"
              }
            }
          ],
          "Type" => "OneOf"
        },
        "Offset" => [1, 1],
        "Type" => "Move"
      }}
    """
    @spec export(Rules.rule) :: Result.result
    def export({:move, %{condition: condition, offset: {r, c}}}) do
      Conditions.export(condition)
      <|> &%{"Type" => "Move", "Condition" => &1, "Offset" => [r, c]}
    end
    def export({:conquer, %{condition: condition, offset: {r, c}}}) do
      Conditions.export(condition)
      <|> &%{"Type" => "Conquer", "Condition" => &1, "Offset" => [r, c]}
    end
    def export({
      :move_combo,
      %{
        condition: condition,
        other: {other_r, other_c},
        my_movement: {my_movement_r, my_movement_c},
        other_movement: {other_movement_r, other_movement_c}
      }
    }) do
      {:ok, &%{"Type" => "MoveCombo", "Condition" => &1, "Other" => &2, "MyMovement" => &3, "OtherMovement" => &4}}
      <~> Conditions.export(condition)
      <~> {:ok, [other_r, other_c]}
      <~> {:ok, [my_movement_r, my_movement_c]}
      <~> {:ok, [other_movement_r, other_movement_c]}
    end
    def export({:promote, %{condition: condition, ranks: ranks}}) do
      Conditions.export(condition)
      <|> &%{"Type" => "Promote", "Condition" => &1, "Ranks" => ranks}
    end
    def export({:defeat, %{condition: condition}}) do
      Conditions.export(condition)
      <|> &%{"Type" => "Defeat", "Condition" => &1}
    end
    def export({:remise, %{condition: condition}}) do
      Conditions.export(condition)
      <|> &%{"Type" => "Defeat", "Condition" => &1}
    end

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Move", "Condition" => condition, "Offset" => [r, c]}) do
      Conditions.imprt(condition)
      <|> &{:move, %{condition: &1, offset: {r, c}}}
    end
    def imprt(%{"Type" => "Conquer", "Condition" => condition, "Offset" => [r, c]}) do
      Conditions.imprt(condition)
      <|> &{:conquer, %{condition: &1, offset: {r, c}}}
    end
    def imprt(%{
      "Type" => "MoveCombo",
      "Condition" => condition,
      "Other" => [other_r, other_c],
      "MyMovement" => [my_movement_r, my_movement_c],
      "OtherMovement" => [other_movement_r, other_movement_c]
    }) do
      {:ok, &{:move_combo, %{condition: &1, other: &2, my_movement: &3, other_movement: &4}}}
      <~> Conditions.imprt(condition)
      <~> {:ok, {other_r, other_c}}
      <~> {:ok, {my_movement_r, my_movement_c}}
      <~> {:ok, {other_movement_r, other_movement_c}}
    end
    def imprt(%{"Type" => "Promote", "Condition" => condition, "Ranks" => ranks}) do
      Conditions.imprt(condition)
      <|> &{:promote, %{condition: &1, ranks: ranks}}
    end
    def imprt(%{"Type" => "Defeat", "Condition" => condition}) do
      Conditions.imprt(condition)
      <|> &{:defeat, %{condition: &1}}
    end
    def imprt(%{"Type" => "Remise", "Condition" => condition}) do
      Conditions.imprt(condition)
      <|> &{:remise, %{condition: &1}}
    end
  end

  defmodule Duelist do
    @type dto :: term
    @spec export(Duel.duelist) :: Result.result
    def export(%{name: name, color: color}) do
      Color.export(color)
      <|> &%{"Name" => name, "Color" => &1}
    end
    def export(_), do: {:error, "Failed to export Duelist"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Name" => name, "Color" => color}) do
      Color.imprt(color)
      <|> &%{name: name, color: &1}
    end
    def imprt(_), do: {:error, "Failed to import Duelist"}
  end

  defmodule Piece do
    @type dto :: term
    @spec export(Duel.pieces) :: Result.result
    def export({:king, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "King", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export({:queen, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "Queen", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export({:rook, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "Rook", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export({:bishop, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "Bishop", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export({:knight, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "Knight", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export({:pawn, %{color: color, rules: rules}}) do
      {:ok, &%{"Type" => "Pawn", "Color" => &1, "Rules" => &2}}
      <~> Color.export(color)
      <~> {:ok, rules}
    end
    def export(_), do: {:error, "Failed to export Piece"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "King", "Color" => color, "Rules" => rules}) do
      {:ok, &{:king, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(%{"Type" => "Queen", "Color" => color, "Rules" => rules}) do
      {:ok, &{:queen, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(%{"Type" => "Rook", "Color" => color, "Rules" => rules}) do
      {:ok, &{:rook, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(%{"Type" => "Bishop", "Color" => color, "Rules" => rules}) do
      {:ok, &{:bishop, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(%{"Type" => "Knight", "Color" => color, "Rules" => rules}) do
      {:ok, &{:knight, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(%{"Type" => "Pawn", "Color" => color, "Rules" => rules}) do
      {:ok, &{:pawn, %{color: &1, rules: &2}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
    end
    def imprt(_), do: {:error, "Failed to import Piece"}
  end

  defmodule Tile do
    alias ChessPlus.Option
    @type dto :: term

    @spec export(Duel.tile) :: Result.result
    def export(%{
      piece: piece,
      color: color,
      selected_by: selected_by,
      conquerable_by: conquerable_by
    }) do
      (Color.export(color)
      <|> &%{"Color" => &1})
      ~>> fn exp -> export_piece(exp, piece) end
      ~>> fn exp -> export_selected_by(exp, selected_by) end
      ~>> fn exp -> export_conquerable_by(exp, conquerable_by) end
    end

    defp export_piece(dto, :none), do: {:ok, dto}
    defp export_piece(dto, {:some, piece}) do
      Piece.export(piece)
      <|> fn p -> Map.put(dto, "Piece", p) end
    end

    defp export_selected_by(dto, :none), do: {:ok, dto}
    defp export_selected_by(dto, {:some, color}) do
      Color.export(color)
      <|> fn c -> Map.put(dto, "SelectedBy", c) end
    end

    defp export_conquerable_by(dto, :none), do: {:ok, dto}
    defp export_conquerable_by(dto, {:some, color}) do
      Color.export(color)
      <|> fn c -> Map.put(dto, "ConquerableBy", c) end
    end

    @spec imprt(dto) :: Result.result
    def imprt(%{"Color" => color} = dto) do
      (Color.imprt(color)
      <|> &%{color: &1})
      ~>> fn obj -> import_piece(obj, dto) end
      ~>> fn obj -> import_selected_by(obj, dto) end
      ~>> fn obj -> import_conquerable_by(obj, dto) end
    end

    defp import_piece(obj, %{"Piece" => piece}) do
      Piece.imprt(piece)
      <|> fn p -> Map.put(obj, :piece, {:some, p}) end
    end
    defp import_piece(obj, _), do: {:ok, Map.put(obj, :piece, :none)}
    defp import_selected_by(obj, %{"SelectedBy" => selected_by}) do
      Color.imprt(selected_by)
      <|> fn c -> Map.put(obj, :selected_by, {:some, c}) end
    end
    defp import_selected_by(obj, _), do: {:ok, Map.put(obj, :selected_by, :none)}
    defp import_conquerable_by(obj, %{"ConquerableBy" => conquerable_by}) do
      Color.imprt(conquerable_by)
      <|> fn c -> Map.put(obj, :conquerably_by, {:some, c}) end
    end
    defp import_conquerable_by(obj, _), do: {:ok, Map.put(obj, :conquerable_by, :none)}
  end
end
