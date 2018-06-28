defmodule ChessPlus.Flow.Duel.UpdateDuelState do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Color
  alias ChessPlus.Delta.VerifyRules
  alias ChessPlus.Result
  alias ChessPlus.Option
  import ChessPlus.Option, only: [<|>: 2]

  @impl(ChessPlus.Wave)
  def flow({{:event, :piece_moved}, _}, sender) do
    update_duel_state(sender)
  end

  defp update_duel_state(%{duel: {:some, id}} = sender) do
    duel = Duel.update!(id, fn duel ->
      (Duel.fetch_player_color(duel, sender)
      <|> fn player_color -> verify_win_conditions(duel, player_color) end)
      |> Option.or_else(duel)
      |> swap_turn()
    end)

    Duel.map_duelists(duel, fn duelist ->
      {:tcp, duelist, {{:duel_state, :update}, duel.duel_state}}
    end)
    |> Result.retn()
  end

  defp verify_win_conditions(duel, player_color) do
    enemy_color = Color.inverse(player_color)

    Enum.reduce(duel.win_conditions, duel, fn
      _, %{duel_state: {:ended, _}} = duel ->
        duel
      {:defeat, _} = win_condition, duel ->
        verify_win_condition(duel, win_condition, player_color, {:ended, {:win, enemy_color}})
      {:remise, _} = win_condition, duel ->
        verify_win_condition(duel, win_condition, player_color, {:ended, :remise})
    end)
  end

  defp verify_win_condition(duel, win_condition, player_color, new_duel_state) do
    if (VerifyRules.verify_rules([win_condition], :none, duel, player_color) |> length) > 0 do
      Duel.update_duel_state(duel, new_duel_state)
    else
      duel
    end
  end

  defp swap_turn(duel) do
    Duel.update_duel_state(duel, fn
      {:turn, :white} -> {:turn, :black}
      {:turn, :black} -> {:turn, :white}
      duel_state -> duel_state
    end)
  end

end
