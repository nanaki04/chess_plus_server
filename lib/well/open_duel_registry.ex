defmodule ChessPlus.Well.OpenDuelRegistry do
  use ChessPlus.Well

  @id "ChessPlus.Well.OpenDuelRegistry"

  @type t :: MapSet.t

  @impl(Guardian.Secret)
  def make_initial_state(_) do
    %{registry: MapSet.new()}
  end

  @spec register(String.t) :: t
  def register(id) do
    update!(@id, fn %{registry: r} -> %{registry: MapSet.put(r, id)} end)
  end

  @spec unregister(String.t) :: t
  def unregister(id) do
    update!(@id, fn %{registry: r} -> %{registry: MapSet.delete(r, id)} end)
  end

  @spec all() :: [String.t]
  def all() do
    fetch(@id)
    |> Map.fetch!(:registry)
    |> MapSet.to_list()
  end

end
