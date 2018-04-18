defmodule ChessPlus.Dto.Waves do
  import ChessPlus.Result, only: [<|>: 2, <~>: 2]
  alias ChessPlus.Dto.Well

  def export_location({domain, invocation}) do
    {:ok, %{"Domain": domain, "Invocation": invocation}}
  end
  def export_location(_), do: {:error, "Failed to export Location"}

  def import_location(%{"Location": %{"Domain": domain, "Invocation": invocation}}) do
    {:ok, {domain, invocation}}
  end
  def import_location(_), do: {:error, "Failed to import Location"}

  def imprt(%{"Location" => %{"Domain" => "duelist", "Invocation" => "join"}, "Player" => player, "ID" => id, "Map" => map}) do
    {:ok, &{{:duelist, :join}, %{player: &1, id: &2, map: &3}}}
    <~> Well.Player.imprt(player)
    <~> {:ok, id}
    <~> Well.Territory.imprt(map)
  end

  def imprt(_), do: {:error, "Failed to import Wave"}

  def export({{:duelist, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Duelist" => &2}}
    <~> export_location(location)
    <~> Well.Duelist.export(amplitude.duelist)
  end

  def export({{:duel, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Duel" => &2}}
    <~> export_location(location)
    <~> Well.Duel.export(amplitude)
  end
end
