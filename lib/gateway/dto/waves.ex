defmodule ChessPlus.Dto.Waves do
  import ChessPlus.Result, only: [<~>: 2]
  alias ChessPlus.Dto.Well
  alias ChessPlus.Result

  @type dto :: term
  @type dto_location :: %{required(String.t) => %{required(String.t) => String.t}}

  @spec export_location({atom, atom}) :: Result.result
  def export_location({domain, invocation}) do
    {:ok, %{"Domain": domain, "Invocation": invocation}}
  end
  def export_location(_), do: {:error, "Failed to export Location"}

  @spec import_location(dto_location) :: Result.result
  def import_location(%{"Location": %{"Domain": domain, "Invocation": invocation}}) do
    {:ok, {domain, invocation}}
  end
  def import_location(_), do: {:error, "Failed to import Location"}

  @spec imprt(dto) :: Result.result
  def imprt(%{"Location" => %{"Domain" => "player", "Invocation" => "join"}, "Name" => name}) do
    {:ok, {{:player, :join}, %{name: name}}}
  end

  def imprt(%{"Location" => %{"Domain" => "duel", "Invocation" => "new"}, "Map" => map}) do
    {:ok, &{{:duel, :new}, %{map: &1}}}
    <~> Well.Territory.imprt(map)
  end

  def imprt(%{"Location" => %{"Domain" => "open_duels", "Invocation" => "all"}}) do
    {:ok, {:open_duels, :all}}
  end

  def imprt(%{"Location" => %{"Domain" => "duelist", "Invocation" => "join"}, "ID" => id}) do
    {:ok, &{{:duelist, :join}, %{id: &1}}}
    <~> {:ok, id}
  end

  def imprt(%{"Location" => %{"Domain" => "duelist", "Invocation" => "add"}, "Duelist" => duelist}) do
    {:ok, &{{:duelist, :add}, %{duelist: &1}}}
    <~> {:ok, duelist}
  end

  def imprt(%{"Location" => %{"Domain" => "tile", "Invocation" => "select"}, "Coordinate" => coordinate}) do
    {:ok, &{{:tile, :select}, %{coordinate: &1}}}
    <~> Well.Coordinate.imprt(coordinate)
  end

  def imprt(%{"Location" => %{"Domain" => "tile", "Invocation" => "deselect"}}) do
    {:ok, {:tile, :deselect}}
  end

  def imprt(%{"Location" => %{"Domain" => "piece", "Invocation" => "add"}, "Piece" => piece, "Coordinate" => coordinate) do
    {:ok, &{{:piece, :add}, %{piece: &1, coordinate: &2}}}
    <~> Well.Piece.imprt(piece)
    <~> Well.Coordinate.imprt(coordinate)
  end

  def imprt(%{"Location" => %{"Domain" => "piece", "Invocation" => "move"}, "Piece" => piece, "From" => from, "To" => to}) do
    {:ok, &{{:piece, :move}, %{piece: &1, from: &2, to: &3}}}
    <~> Well.Piece.imprt(piece)
    <~> Well.Coordinate.imprt(from)
    <~> Well.Coordinate.imprt(to)
  end

  def imprt(%{"Location" => %{"Domain" => "piece", "Invocation" => "remove"}, "Coordinate" => coordinate}) do
    {:ok, &{{:piece, :remove}, %{coordinate: &1}}}
    <~> Well.Coordinate.imprt(coordinate)
  end

  def imprt(%{"Location" => %{"Domain" => "piece", "Invocation" => "promote"}, "Piece" => piece}) do
    {:ok, &{{:piece, :promote}, &1}}
    <~> Well.Piece.imprt(piece)
  end

  def imprt(%{"Location" => %{"Domain" => "buffs", "Invocation" => "update"}, "buffs" => buffs}) do
    {:ok, &{{:buffs, :update}, &1}}
    <~> Well.Buffs.imprt(buffs)
  end

  def imprt(%{"Location" => %{"Domain" => d, "Invocation" => i}}), do: {:error, "Failed to import Wave: " <> d <> " : " <> i}
  def imprt(w), do: {:error, "Failed to import Wave: " <> Poison.encode!(w)}

  @spec export(ChessPlus.Wave.wave) :: Result.result
  def export({{:player, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Player" => &2}}
    <~> export_location(location)
    <~> Well.Player.export(amplitude)
  end

  def export({{:player, :created} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Player" => &2}}
    <~> export_location(location)
    <~> Well.Player.export(amplitude)
  end

  def export({{:duel, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Duel" => &2, "Tiles" => &3, "TileSelections" => &4, "Pieces" => &5, "Rules" => &6}}
    <~> export_location(location)
    <~> Well.Duel.export(amplitude)
    <~> Well.Tiles.export(amplitude.board.tiles)
    <~> Well.TileSelections.export(amplitude.board.tiles)
    <~> Well.Pieces.export(amplitude.board.tiles)
    <~> Well.Rules.export(amplitude.rules)
  end

  def export({{:open_duels, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Duels" => &2}}
    <~> export_location(location)
    <~> {:ok, amplitude.duels}
  end

  def export({{:duelist, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Duelist" => &2}}
    <~> export_location(location)
    <~> Well.Duelist.export(amplitude.duelist)
  end

  def export({{:tile, :confirm_select} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Player" => &2, "Coordinate" => &3}}
    <~> export_location(location)
    <~> Well.Color.export(amplitude.player)
    <~> Well.Coordinate.export(amplitude.coordinate)
  end

  def export({{:tile, :confirm_deselect} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Player" => &2}}
    <~> export_location(location)
    <~> Well.Color.export(amplitude.player)
  end

  def export({{:piece, :add} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Piece" => &2, "Coordinate" => &3}}
    <~> Well.Piece.export(amplitude.piece)
    <~> Well.Coordinate.export(amplitude.coordinate)
  end

  def export({{:piece, :move} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Piece" => &2, "From" => &3, "To" => &4}}
    <~> export_location(location)
    <~> Well.Piece.export(amplitude.piece)
    <~> Well.Coordinate.export(amplitude.from)
    <~> Well.Coordinate.export(amplitude.to)
  end

  def export({{:piece, :conquer} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Piece" => &2, "From" => &3, "To" => &4}}
    <~> export_location(location)
    <~> Well.Piece.export(amplitude.piece)
    <~> Well.Coordinate.export(amplitude.from)
    <~> Well.Coordinate.export(amplitude.to)
  end

  def export({{:piece, :remove} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Coordinate" => &2}}
    <~> export_location(location)
    <~> Well.Coordinate.export(amplitude.coordinate)
  end

  def export({{:piece, :promote} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Piece" => &2}}
    <~> export_location(location)
    <~> Well.Piece.export(amplitude)
  end

  def export({{:buffs, :update} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Buffs" => &2}}
    <~> export_location(location)
    <~> Well.Buffs.export(amplitude)
  end

  def export({{:global, :error} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "Reason" => &2}}
    <~> export_location(location)
    <~> {:ok, amplitude}
  end

  def export({{:duel_state, :update} = location, amplitude}) do
    {:ok, &%{"Location" => &1, "DuelState" => &2}}
    <~> export_location(location)
    <~> Well.DuelState.export(amplitude)
  end

  def export(_), do: {:error, "Failed to export Wave"}
end
