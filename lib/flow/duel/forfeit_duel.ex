defmodule ChessPlus.Flow.Duel.Forfeit do
  use ChessPlus.Wave
  alias ChessPlus.Well.Duel
  alias ChessPlus.Well.Duel.Color
  alias ChessPlus.Option
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:duelist, :forfeit}, %{duel: {:some, duel_id}} = sender) do
    Duel.update(duel_id, fn duel ->
      Duel.fetch_player_color(duel, sender)
      |> Option.map(&Color.inverse/1)
      |> Option.map(fn enemy_color -> Duel.update_duel_state(duel, {:ended, {:win, enemy_color}}) end)
      |> Option.to_result()
    end)
    |> Result.map(fn duel ->

      commands = Duel.map_duelists(duel, fn p ->
        [
          {:tcp, p, {{:duel_state, :update}, duel.duel_state}}
        ]
      end)
      |> Enum.flat_map(&(&1))

      commands
      #      [
      #        {:event, sender, {{:event, :duel_left}, duel.id}} |
      #        commands
      #      ]
    end)
  end

  def flow(_, _), do: {:ok, []}

end
