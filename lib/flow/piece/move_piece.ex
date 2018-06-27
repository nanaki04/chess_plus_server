defmodule ChessPlus.Flow.MovePiece do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Result
  alias ChessPlus.Matrix

  @impl(ChessPlus.Wave)
  def flow(
    {{:piece, :move}, %{piece: piece, from: {from_r, from_c}, to: {to_r, to_c}} = ampl},
    %{duel: {:some, id}} = sender)
  do
    Duel.update!(id, fn duel ->
      duel.board.tiles
      |> Matrix.update(from_r, from_c, fn tile ->
        %{tile | piece: :none}
      end)
      |> Matrix.update(to_r, to_c, fn tile ->
        %{tile | piece: {:some, Piece.map(piece, fn p -> Map.update(p, :move_count, 1, &(&1 + 1)) end)}}
      end)
      |> (fn tiles ->
        %{duel | board: %{duel.board | tiles: tiles}}
      end).()
    end)
    |> Duel.map_duelists(fn duelist ->
      {:udp, duelist, {{:piece, :conquer}, ampl}}
    end)
    |> (&[
      {:event, sender, {{:event, :piece_moved}, piece}} | &1
    ]).()
    |> Result.retn()
  end

end
