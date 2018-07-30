defmodule ChessPlus.Flow.MovePiece do
  use ChessPlus.Wave
  alias ChessPlus.Well.Rules
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Coordinate
  alias ChessPlus.Delta.SimulateRules
  alias ChessPlus.Result
  alias ChessPlus.Option
  import ChessPlus.Option, only: [~>>: 2, <~>: 2]

  @impl(ChessPlus.Wave)
  def flow(
    {{:piece, :move}, %{piece: piece, to: to} = ampl},
    %{duel: {:some, id}} = sender)
  do
    duel = Duel.fetch(id)

    Duel.find_rules_targetting_coord(duel, to, piece)
    |> Rules.sort_rules()
    |> Option.from_list()
    |> Option.map(&Kernel.hd/1)
    |> Option.map(fn rule -> apply_move_rule(duel, rule, ampl) end)
    |> Option.to_result()
    |> Result.flatten()
    |> Result.map(fn {duel, waves} ->
      Duel.update!(id, fn _ -> duel end)
      [{:event, sender, {{:event, :piece_moved}, piece}} | waves]
    end)
  end

  defp apply_move_rule(
    duel,
    {:move_combo, %{other: other, other_movement: other_movement}} = rule,
    %{piece: piece, from: from} = ampl)
  do
    maybe_other_coord = Coordinate.apply_offset(from, other) |> Option.from_result()
    maybe_other_piece = maybe_other_coord ~>> fn coord -> Duel.fetch_piece(duel, coord) end
    maybe_other_target = Coordinate.apply_offset(maybe_other_coord, other_movement)

    ({:some, fn other_coord, other_piece, other_target ->
      Duel.increment_piece_move_count(duel, from)
      |> Result.bind(fn duel -> SimulateRules.simulate_rule(duel, rule, {:some, piece}) end)
      |> Result.map(fn duel ->
        waves = Duel.map_duelists(duel, fn duelist ->
          [
            {:tcp, duelist, {{:piece, :conquer}, ampl}},
            {:tcp, duelist, {{:piece, :conquer}, %{piece: other_piece, from: other_coord, to: other_target}}},
          ]
        end)
        |> Enum.flat_map(&(&1))

        {duel, waves}
      end)
    end}
    <~> maybe_other_coord
    <~> maybe_other_piece
    <~> maybe_other_target)
    |> Option.to_result()
    |> Result.flatten()
  end

  defp apply_move_rule(
    duel,
    {_, %{offset: _}} = rule,
    %{piece: piece, from: from} = ampl)
  do
    Duel.increment_piece_move_count(duel, from)
    |> Result.bind(fn duel -> SimulateRules.simulate_rule(duel, rule, {:some, piece}) end)
    |> Result.map(fn duel ->
      waves = Duel.map_duelists(duel, fn duelist ->
        {:tcp, duelist, {{:piece, :conquer}, ampl}}
      end)

      {duel, waves}
    end)
  end

  defp apply_move_rule(_, _, _), do: {:error, "No valid rule found for moving piece to designated location"}
end
