defmodule ChessPlus.Flow.Duel.LeaveDuel do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Color
  alias ChessPlus.Result
  alias ChessPlus.Option

  @spec flow(wave, sender) :: Result.result
  def flow({{:event, :player_deleted}, duelist}, _), do: handle(duelist)
  def flow({:duelist, :remove}, sender), do: handle(sender)
  def flow(_, _), do: {:ok, []}

  defp handle(%{duel: {:some, duel_id}} = player) do
    duel = Duel.fetch(duel_id)
    leave_duel(player, Duel.fetch_player(duel, player))
  end

  defp handle(_), do: {:ok, []}

  defp leave_duel(%{duel: {:some, duel_id}} = player, {:some, duelist}) do
    Duel.update(duel_id, fn duel ->
      Duel.fetch_player_color(duel, player)
      |> Option.map(&Color.inverse/1)
      |> Option.map(fn enemy_color -> Duel.update_duel_state(duel, fn
        {:ended, _} = duel_state -> duel_state
        _ -> {:ended, {:win, enemy_color}}
      end) end)
      |> Option.map(fn duel -> Duel.remove_player(duel, player) end)
      |> Option.to_result()
    end)
    |> Result.map(fn duel ->

      commands = if length(duel.duelists) == 0 do
        :ok = Duel.stop_gracefully(duel_id, true)
        [{:event, player, {{:event, :duel_deleted}, duel}}]
      else
        []
      end

      commands = commands ++ (Duel.map_duelists(duel, fn p ->
        [
          {:tcp, p, {{:duelist, :remove}, duelist}},
          {:tcp, p, {{:duel_state, :update}, duel.duel_state}}
        ]
      end)
      |> Enum.flat_map(fn c -> c end))

      commands ++ [
        {:event, player, {{:event, :duel_left}, duel.id}}
      ]
    end)
  end

  defp leave_duel(_, _), do: {:ok, []}

end
