defmodule ChessPlus.Flow.FindOpenDuels do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry
  alias ChessPlus.Result

  @spec flow(wave, sender) :: Result.result
  def flow({:open_duels, :all}, sender) do
    OpenDuelRegistry.all()
    |> (&[{:udp, sender, {{:open_duels, :add}, %{duels: &1}}}]).()
    |> Result.retn()
  end
end
