defmodule ChessPlus.Flow.FindOpenDuels do
  use ChessPlus.Wave
  alias ChessPlus.Well.OpenDuelRegistry
  alias ChessPlus.Result

  @spec invoke(OpenDuelRegistry.t, receiver) :: wave_downstream
  def invoke(registry, receiver) do
    {:udp, receiver, {{:open_duels, :add}, %{duels: registry}}}
  end

  @spec flow(wave, sender) :: Result.result
  def flow({:open_duels, :all}, sender) do
    OpenDuelRegistry.all()
    |> invoke(sender)
    |> Result.retn()
  end
end
