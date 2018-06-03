defmodule ChessPlus.Flow.MovePiece do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Result
  alias ChessPlus.Matrix

  @impl(ChessPlus.Wave)
  def flow(
    {{:piece, :move}, %{piece: piece, from: {from_r, from_c}, to: {to_r, to_c}} = ampl},
    %{duel: {:some, id}})
  do
    Duel.update!(id, fn duel ->
      duel.board.tiles
      |> Matrix.update(from_r, from_c, fn tile ->
        %{tile | piece: :none}
      end)
      |> Matrix.update(to_r, to_c, fn tile ->
        %{tile | piece: {:some, piece}}
      end)
      |> (fn tiles ->
        %{duel | board: %{duel.board | tiles: tiles}}
      end).()
    end)
    |> Duel.map_duelists(fn duelist ->
      {:udp, duelist, {{:piece, :conquer}, ampl}}
    end)
    |> Result.retn()
  end

end
