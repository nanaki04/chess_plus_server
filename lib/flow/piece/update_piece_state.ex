defmodule ChessPlus.Flow.Piece.UpdatePieceState do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Well.Rules
  alias ChessPlus.Delta.SimulateRules
  alias ChessPlus.Delta.VerifyRules
  alias ChessPlus.Option
  alias ChessPlus.Result

  @impl(ChessPlus.Wave)
  def flow({{:event, :piece_moved}, piece}, %{duel: {:some, id}}) do
    duel = Duel.fetch(id)

    rules = Duel.fetch_piece_rules(duel, piece)
    |> Rules.filter_on_piece_moved_rules()
    |> VerifyRules.verify_rules({:some, piece}, duel)

    duel_result = rules
    |> Enum.reduce({:ok, duel}, fn
      rule, {:ok, duel} -> SimulateRules.simulate_rule(duel, rule, {:some, piece})
      _, err -> err
    end)

    Duel.update(id, fn _ -> duel_result end)

    Result.bind(duel_result, fn duel ->
      ChessPlus.Logger.warn("REDUCE")
      Enum.reduce(rules, {:ok, []}, fn
        {:promote, _}, {:ok, waves} ->
          Piece.id(piece)
          |> Option.bind(fn id -> Duel.fetch_piece_by_id(duel, id) end)
          |> Option.map(fn piece ->
            Duel.map_duelists(duel, fn duelist ->
              {:tcp, duelist, {{:piece, :promote}, piece}}
            end) ++ waves
          end)
          |> Option.to_result("Failed to report promoted piece")
        _, waves -> waves
      end)
    end)
    |> IO.inspect(label: "update piece state result")
  end

end
