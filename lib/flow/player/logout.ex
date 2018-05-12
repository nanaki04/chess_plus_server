defmodule ChessPlus.Flow.Logout do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player
  alias ChessPlus.Well.PlayerRegistry
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:player, :remove}, %{name: name} = player) do
    case Player.stop_gracefully(name, true) do
      :ok ->
        {:ok, [
          {:event, player, {{:event, :player_deleted}, player}}
        ]}
      # TODO implement if stop_gracefully has proper errors
      # _ ->
      #   {:error, "Error deleting player: " <> name}
    end
  end

  def flow({:player, :remove}, _) do
    {:ok, []}
  end

end
