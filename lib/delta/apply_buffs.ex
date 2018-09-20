defmodule ChessPlus.Delta.ApplyBuffs do
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Buff
  alias ChessPlus.Well.Duel.Piece
  alias ChessPlus.Result

  @type duel :: Duel.duel
  @type buff :: Duel.active_buff

  @spec apply_buff(duel, buff) :: Result.result
  def apply_buff(duel, %{type: :add_rule, %{rules: rules, piece_id: piece_id}}) do
    Duel.update_piece_by_id(duel, piece_id, fn
      :none ->
        :none
      {:some, piece} ->
        %{piece | rules: piece.rules ++ rules}
        |> Option.retn()
    end)
  end

  @spec unapply_buff(duel, buff) :: Result.result
  def unapply_buff(duel, %{type: :add_rule, %{rules: rules, piece_id: piece_id}}) do
    Duel.update_piece_by_id(duel, piece_id, fn
      :none ->
        :none
      {:some, piece} ->
        Enum.reduce(rules, piece, fn rule -> %{piece | rules: List.delete(piece.rules, rule)} end)
        |> Option.retn()
    end)
  end

  @spec get_apply_waves(duel, buff) :: [wave]
  def get_apply_waves(duel, %{type: :add_rule, %{rules: rules, piece_id: piece_id}}) do
    maybe_piece = Duel.fetch_piece_by_id(duel, piece_id)
    maybe_coord = Option.bind(maybe_piece, fn piece -> Piece.find_piece_coordinate(duel, piece) end)

    {:some, fn piece, coord ->
      Duel.map_duelists(duel, fn duelist ->
        {:tcp, duelist, {{:piece, :add}, %{piece: piece, coordinate: coord}}}
      end)
    end}
    <~> maybe_piece
    <~> maybe_coord
    |> Option.or_else([])
    |> Result.retn()
  end

  @spec get_unapply_waves(duel, buff) :: [wave]
  def get_unapply_waves(duel, %{type: :add_rule, _} = buff) do
    get_apply_waves(duel, buff)
  end

end
