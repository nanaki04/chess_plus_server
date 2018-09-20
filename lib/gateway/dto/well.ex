defmodule ChessPlus.Dto.Well do
  alias ChessPlus.Result
  alias ChessPlus.Option
  alias ChessPlus.Well.Rules, as: WellRules
  alias ChessPlus.Well.Player, as: WellPlayer
  alias ChessPlus.Well.Duel, as: WellDuel
  import ChessPlus.Result, only: [<|>: 2, <~>: 2, ~>>: 2]

  defmodule Player do
    @type dto :: term
    @spec export(WellPlayer.player) :: Result.result
    def export(%{name: name}) do
      {:ok, %{"Name" => name}}
    end
    def export(_), do: {:error, "Failed to export Player"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Name" => name}) do
      {:ok, %WellPlayer{name: name}}
    end
    def imprt(_), do: {:error, "Failed to import Player"}
  end

  defmodule Territory do
    @type dto :: term
    @spec export(WellDuel.territory) :: Result.result
    def export(:classic), do: {:ok, "Classic"}
    def export(:debug), do: {:ok, "Debug"}
    def export(_), do: {:error, "Failed to export Territory"}

    @spec imprt(dto) :: Result.result
    def imprt("Classic"), do: {:ok, :classic}
    def imprt("Debug"), do: {:ok, :debug}
    def imprt(_), do: {:error, "Failed to import Territory"}
  end

  defmodule Color do
    @type dto :: term
    @spec export(WellRules.color) :: Result.result
    def export(:black), do: {:ok, "Black"}
    def export(:white), do: {:ok, "White"}
    def export(_), do: {:error, "Failed to export Color"}

    @spec imprt(dto) :: Result.result
    def imprt("Black"), do: {:ok, :black}
    def imprt("White"), do: {:ok, :white}
    def imprt(_), do: {:error, "Failed to import Color"}
  end

  defmodule Row do
    @type dto :: term
    @spec export(WellDuel.row) :: Result.result
    def export(row), do: WellDuel.Row.to_num(row) <|> (&to_string/1)

    @spec imprt(dto) :: Result.result
    def imprt(row) when is_number(row), do: WellDuel.Row.from_num(row)
    def imprt(row) when is_binary(row), do: Integer.parse(row) |> elem(0) |> WellDuel.Row.from_num()
  end

  defmodule Column do
    @type dto :: term
    @spec export(WellDuel.column) :: Result.result
    def export(:a), do: {:ok, "A"}
    def export(:b), do: {:ok, "B"}
    def export(:c), do: {:ok, "C"}
    def export(:d), do: {:ok, "D"}
    def export(:e), do: {:ok, "E"}
    def export(:f), do: {:ok, "F"}
    def export(:g), do: {:ok, "G"}
    def export(:h), do: {:ok, "H"}
    def export(:i), do: {:ok, "I"}
    def export(:j), do: {:ok, "J"}
    def export(:k), do: {:ok, "K"}
    def export(:l), do: {:ok, "L"}
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
    def imprt("I"), do: {:ok, :i}
    def imprt("J"), do: {:ok, :j}
    def imprt("K"), do: {:ok, :k}
    def imprt("L"), do: {:ok, :l}
    def imprt(_), do: {:error, "Failed to import Column"}
  end

  defmodule Coordinate do
    @type dto :: term
    @spec export(WellDuel.coordinate) :: Result.result
    def export({r, c}) do
      {:ok, &"#{&1}:#{&2}"}
      <~> Row.export(r)
      <~> Column.export(c)
    end
    def export(_), do: {:error, "Failed to export Coordinate"}

    @spec imprt(dto) :: Result.result
    def imprt(coord) do
      case String.split(coord, ":") do
        [row, column] ->
          {:ok, &{&1, &2}}
          <~> Row.imprt(row)
          <~> Column.imprt(column)
        _ ->
          {:error, "Failed to import Coordinate"}
      end
    end
  end

  defmodule DuelistType do
    @type dto :: term
    @spec export(WellRules.duelist_type) :: Result.result
    def export(:any), do: {:ok, %{"Type" => "Any"}}
    def export(:self), do: {:ok, %{"Type" => "Self"}}
    def export(:other), do: {:ok, %{"Type" => "Other"}}
    def export({:player, color}) do
      Color.export(color)
      <|> fn c -> %{"Type" => "Player", "Player" => c} end
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

  defmodule PieceType do
    def export(:pawn), do: {:ok, "Pawn"}
    def export(:bishop), do: {:ok, "Bishop"}
    def export(:knight), do: {:ok, "Knight"}
    def export(:rook), do: {:ok, "Rook"}
    def export(:queen), do: {:ok, "Queen"}
    def export(:king), do: {:ok, "King"}
    def export(p), do: {:error, "No such PieceType: " <> p}

    def imprt("Pawn"), do: {:ok, :pawn}
    def imprt("Bishop"), do: {:ok, :bishop}
    def imprt("Knight"), do: {:ok, :knight}
    def imprt("Rook"), do: {:ok, :rook}
    def imprt("Queen"), do: {:ok, :queen}
    def imprt("King"), do: {:ok, :king}
    def imprt(p), do: {:error, "No such PieceType: " <> p}
  end

  defmodule Condition do
    @type dto :: term
    @spec export(WellRules.condition) :: Result.result
    def export(:always), do: {:ok, %{"Type" => "Always"}}
    def export(:move_count), do: {:ok, %{"Type" => "MoveCount"}}
    def export(:target_move_count), do: {:ok, %{"Type" => "TargetMoveCount"}}
    def export(:exposes_king), do: {:ok, %{"Type" => "ExposesKing"}}
    def export(:path_blocked), do: {:ok, %{"Type" => "PathBlocked"}}
    def export({:occupied_by, duelist_type}) do
      DuelistType.export(duelist_type)
      <|> fn d -> %{"Type" => "OccupiedBy", "OccupiedBy" => d} end
    end
    def export(:conquerable), do: {:ok, %{"Type" => "Conquerable"}}
    def export(:movable), do: {:ok, %{"Type" => "Movable"}}
    def export(:defendable), do: {:ok, %{"Type" => "Defendable"}}
    def export(:exposed_while_moving), do: {:ok, %{"Type" => "ExposedWhileMoving"}}
    def export({:other_piece_type, piece_type}) do
      PieceType.export(piece_type)
      <|> fn t -> %{"Type" => "OtherPieceType", "OtherPieceType" => t} end
    end
    def export({:other_owner, owner}) do
      DuelistType.export(owner)
      <|> fn d -> %{"Type" => "OtherOwner", "OtherOwner" => d} end
    end
    def export({:row, row_number}), do: {:ok, %{"Type" => "Row", "Row" => row_number}}
    def export({:column, column_number}), do: {:ok, %{"Type" => "Column", "Column" => column_number}}
    def export({:remaining_piece_types, piece_types}) do
      (Enum.map(piece_types, &PieceType.export/1)
      |> Result.unwrap())
      <|> fn pt -> %{"Type" => "RemainingPieceTypes", "PieceTypes" => pt} end
    end
    def export(_), do: {:error, "Failed to export Condition"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Always"}), do: {:ok, :always}
    def imprt(%{"Type" => "MoveCount"}), do: {:ok, :move_count}
    def imprt(%{"Type" => "TargetMoveCount"}), do: {:ok, :target_move_count}
    def imprt(%{"Type" => "ExposesKing"}), do: {:ok, :exposes_king}
    def imprt(%{"Type" => "PathBlocked"}), do: {:ok, :path_blocked}
    def imprt(%{"Type" => "OccupiedBy", "OccupiedBy" => occupied_by}) do
      DuelistType.imprt(occupied_by)
      <|> fn d -> {:occupied_by, d} end
    end
    def imprt(%{"Type" => "Conquerable"}), do: {:ok, :conquerable}
    def imprt(%{"Type" => "Movable"}), do: {:ok, :movable}
    def imprt(%{"Type" => "Defendable"}), do: {:ok, :defendable}
    def imprt(%{"Type" => "ExposedWhileMoving"}), do: {:ok, :exposed_while_moving}
    def imprt(%{"Type" => "OtherPieceType", "OtherPieceType" => piece_type}) do
      PieceType.imprt(piece_type)
      <|> fn t -> {:other_piece_type, t} end
    end
    def imprt(%{"Type" => "OtherOwner", "OtherOwner" => owner}) do
      DuelistType.imprt(owner)
      <|> fn d -> {:other_owner, d} end
    end
    def imprt(%{"Type" => "Row", "Row" => row_number}), do: {:ok, {:row, row_number}}
    def imprt(%{"Type" => "Column", "Column" => column_number}), do: {:ok, {:column, column_number}}
    def imprt(%{"Type" => "RemainingPieceTypes", "PieceTypes" => piece_types}) do
      (Enum.map(piece_types, &PieceType.imprt/1)
      |> Result.unwrap())
      <|> fn pt -> {:remaining_piece_types, pt} end
    end
    def imprt(_), do: {:error, "Failed to import Condition"}
  end

  defmodule Operator do
    @type dto :: term
    @spec export(WellRules.operator) :: Result.result
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
    @spec export(WellRules.clause) :: Result.result
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
    @spec export(WellRules.conditions) :: Result.result
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
    @spec export(WellRules.rule) :: Result.result
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
    def export({
      :conquer_combo,
      %{
        condition: condition,
        target_offset: {target_r, target_c},
        my_movement: {my_movement_r, my_movement_c}
      }
    }) do
      {:ok, &%{"Type" => "ConquerCombo", "Condition" => &1, "TargetOffset" => &2, "MyMovement" => &3}}
      <~> Conditions.export(condition)
      <~> {:ok, [target_r, target_c]}
      <~> {:ok, [my_movement_r, my_movement_c]}
    end
    def export({
      :add_buff_on_move,
      %{
        condition: condition,
        target_offset: {target_r, target_c},
        buff_id: buff_id
      }
    }) do
      {:ok, &%{"Type" => "AddBuffOnMove", "Condition" => &1, "TargetOffset" => &2, "BuffId" => &3}}
      <~> Conditions.export(condition)
      <~> {:ok, [target_r, target_c]}
      <~> {:ok, buff_id}
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
    def imprt(%{
      "Type" => "ConquerCombo",
      "Condition" => condition,
      "TargetOffset" => [target_r, target_c],
      "MyMovement" => [my_movement_r, my_movement_c]
    }) do
      {:ok, &{:conquer_combo, %{condition: &1, target_offset: &2, my_movement: &3}}}
      <~> Conditions.imprt(condition)
      <~> {:ok, {target_r, target_c}}
      <~> {:ok, {my_movement_r, my_movement_c}}
    end
    def imprt(%{
      "Type" => "AddBuffOnMove",
      "Condition" => condition,
      "TargetOffset" => [target_r, target_c],
      "BuffId" => buff_id
    }) do
      {:ok, &{:add_buff_on_move, %{condition: &1, target_offset: &2, buff_id: &3}}}
      <~> Conditions.imprt(condition)
      <~> {:ok, {target_r, target_c}}
      <~> buff_id
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
    @spec export(WellDuel.duelist) :: Result.result
    def export(%{name: name, color: color}) do
      Color.export(color)
      <|> &%{"Name" => name, "Color" => &1}
    end
    def export(x), do: {:error, "Failed to export Duelist: " <> Poison.encode!(x)}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Name" => name, "Color" => color}) do
      Color.imprt(color)
      <|> &%{name: name, color: &1}
    end
    def imprt(_), do: {:error, "Failed to import Duelist"}
  end

  defmodule Piece do
    @type dto :: term
    @spec export(WellDuel.pieces) :: Result.result
    def export({:king, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "King", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export({:queen, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "Queen", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export({:rook, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "Rook", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export({:bishop, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "Bishop", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export({:knight, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "Knight", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export({:pawn, %{color: color, rules: rules, id: id, move_count: move_count}}) do
      {:ok, &%{"Type" => "Pawn", "Color" => &1, "Rules" => &2, "Id" => &3, "MoveCount" => &4}}
      <~> Color.export(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def export(_), do: {:error, "Failed to export Piece"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "King", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:king, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(%{"Type" => "Queen", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:queen, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(%{"Type" => "Rook", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:rook, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(%{"Type" => "Bishop", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:bishop, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(%{"Type" => "Knight", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:knight, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(%{"Type" => "Pawn", "Color" => color, "Rules" => rules, "Id" => id, "MoveCount" => move_count}) do
      {:ok, &{:pawn, %{color: &1, rules: &2, id: &3, move_count: &4}}}
      <~> Color.imprt(color)
      <~> {:ok, rules}
      <~> {:ok, id}
      <~> {:ok, move_count}
    end
    def imprt(_), do: {:error, "Failed to import Piece"}
  end

  defmodule Buffs do
    alias ChessPlus.Well.Duel

    @type dto :: term
    @type buff :: Duel.active_buff

    @spec export([buff]) :: Result.result
    def export(buffs) do
      Enum.map(buffs, fn 
    end

    @spec imprt(dto) :: Result.result
    def imprt(dto) do

    end
  end

  defmodule TileSelections do
    alias ChessPlus.Matrix

    @type dto :: term

    @spec export(Matrix.matrix) :: Result.result
    def export(tiles) do
      Matrix.reduce(
        tiles,
        {:ok, %{"Black" => %{"Conquerable" => []}, "White" => %{"Conquerable" => []}}},
        fn
          row, column, tile, {:ok, selections} ->
            (tile.selected_by
            |> Option.map(fn color -> 
              {:ok, fn c, coord -> put_in(selections, [c, "Selected"], coord) end}
              <~> Color.export(color)
              <~> Coordinate.export({row, column})
            end)
            |> Option.or_else({:ok, selections}))
            ~>> (fn selections ->
              tile.conquerable_by
              |> Option.map(fn color ->
                {:ok, fn c, coord -> update_in(selections, [c, "Conquerable"], &[coord | &1]) end}
                <~> Color.export(color)
                <~> Coordinate.export({row, column})
              end)
              |> Option.or_else({:ok, selections})
            end)
          _, _, _, err ->
            err
        end
      )
    end

    def imprt(_), do: {:error, "TileSelections import not supported at the moment"}
  end

  defmodule Pieces do
    alias ChessPlus.Matrix

    @type dto :: term

    @spec export(Matrix.matrix) :: Result.result
    def export(tiles) do
      Matrix.reduce(tiles, {:ok, %{}}, fn row, column, tile, map ->
        case tile.piece do
          {:some, p} ->
            {:ok, fn pieces, coord, piece -> Map.put(pieces, coord, piece) end}
            <~> map
            <~> Coordinate.export({row, column})
            <~> Piece.export(p)
          :none ->
            map
        end
      end)
    end

    @spec imprt(dto) :: Result.result
    def imprt(_), do: {:error, "Import Piece not supported at the moment"}
  end

  defmodule Tile do
    @type dto :: term

    @spec export(WellDuel.tile) :: Result.result
    def export(%{color: color}) do
      {:ok, &%{"Color" => &1}}
      <~> Color.export(color)
    end

    def _export(%{
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
    def imprt(%{"Color" => color}) do
      {:ok, &%{color: &1}}
      <~> Color.imprt(color)
    end
    def _imprt(%{"Color" => color} = dto) do
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
      <|> fn c -> Map.put(obj, :conquerable_by, {:some, c}) end
    end
    defp import_conquerable_by(obj, _), do: {:ok, Map.put(obj, :conquerable_by, :none)}
  end

  defmodule Tiles do
    alias ChessPlus.Matrix

    @type dto :: term
    @spec export(Matrix.matrix) :: Result.result
    def export(tiles) do
      Matrix.reduce(tiles, {:ok, %{}}, fn
        r, c, item, {:ok, map} ->
          {:ok, &Map.put/3}
          <~> {:ok, map}
          <~> Coordinate.export({r, c})
          <~> Tile.export(item)
        _, _, _, error ->
          error
      end)
    end

    @spec imprt(dto) :: Result.result
    def imprt(tiles) do
      Enum.reduce(tiles, {:ok, Matrix.empty()}, fn {coord, tile}, matrix ->
        {:ok, fn m, {r, c}, tile -> Matrix.add(m, r, c, tile) end}
        <~> matrix
        <~> Coordinate.imprt(coord)
        <~> Tile.imprt(tile)
      end)
    end
  end

  defmodule Rules do
    @type dto :: term
    @spec export(WellRules.rules) :: Result.result
    def export(rules) do
      Enum.map(rules, fn {idx, rule} -> Rule.export(rule) <|> &{to_string(idx), &1} end)
      |> Result.unwrap()
      |> Result.into(%{})
    end

    @spec imprt(dto) :: Result.result
    def imprt(rules) do
      Enum.map(rules, fn {idx, rule} -> Rule.imprt(rule) <|> &{Integer.parse(idx) |> elem(0), &1} end)
      |> Result.unwrap()
      |> Result.into(%{})
    end
  end

  defmodule DuelState do
    @type dto :: term
    @spec export(ChessPlus.Well.Duel.duel_state) :: Result.result
    def export({:turn, :black}), do: {:ok, %{"Type" => "Turn", "Turn" => %{"Type" => "Player", "Player" => "Black"}}}
    def export({:turn, :white}), do: {:ok, %{"Type" => "Turn", "Turn" => %{"Type" => "Player", "Player" => "White"}}}
    def export({:turn, :any}), do: {:ok, %{"Type" => "Turn", "Turn" => "Any"}}
    def export(:paused), do: {:ok, %{"Type" => "Paused"}}
    def export({:ended, :remise}), do: {:ok, %{"Type" => "Ended", "Ended" => %{"Type" => "Remise"}}}
    def export({:ended, {:win, :black}}), do: {:ok, %{"Type" => "Ended", "Ended" => %{"Type" => "Win", "Value" => "Black"}}}
    def export({:ended, {:win, :white}}), do: {:ok, %{"Type" => "Ended", "Ended" => %{"Type" => "Win", "Value" => "White"}}}
    def export(_), do: {:error, "Failed to export duel_state"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Type" => "Turn", "Turn" => %{"Type" => "Player", "Player" => "Black"}}), do: {:ok, {:turn, :black}}
    def imprt(%{"Type" => "Turn", "Turn" => %{"Type" => "Player", "Player" => "White"}}), do: {:ok, {:turn, :white}}
    def imprt(%{"Type" => "Turn", "Turn" => "Any"}), do: {:ok, {:turn, :any}}
    def imprt(%{"Type" => "Paused"}), do: {:ok, :paused}
    def imprt(%{"Type" => "Ended", "Ended" => %{"Type" => "Remise"}}), do: {:ok, {:ended, :remise}}
    def imprt(%{"Type" => "Ended", "Ended" => %{"Type" => "Win", "Value" => "Black"}}), do: {:ok, {:ended, {:win, :black}}}
    def imprt(%{"Type" => "Ended", "Ended" => %{"Type" => "Win", "Value" => "White"}}), do: {:ok, {:ended, {:win, :white}}}
    def imprt(_), do: {:error, "Failed to import DuelState"}
  end

  defmodule Duel do
    @type dto :: term
    @spec export(WellDuel.duel) :: Result.result
    def export(%WellDuel{duelists: duelists, duel_state: duel_state}) do
      {:ok, &%{"Duelists" => &1, "DuelState" => &2}}
      <~> (Enum.map(duelists, &Duelist.export/1) |> Result.unwrap())
      <~> DuelState.export(duel_state)
    end
    def export(_), do: {:error, "Failed to export Duel"}

    @spec imprt(dto) :: Result.result
    def imprt(%{"Duelists" => duelists, "DuelState" => duel_state}) do
      {:ok, &%WellDuel{duelists: &1, duel_state: &2}}
      <~> (Enum.map(duelists, &Duelist.imprt/1) |> Result.unwrap())
      <~> DuelState.imprt(duel_state)
    end
    def imprt(_), do: {:error, "Failed to import Duel"}
  end

end
