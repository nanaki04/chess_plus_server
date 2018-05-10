defmodule ChessPlus.Well.Duel do
  use ChessPlus.Well
  alias ChessPlus.Matrix
  alias ChessPlus.Result
  alias __MODULE__, as: Duel

  @type territory :: :classic

  @type color :: :black | :white

  @type row :: :one
    | :two
    | :three
    | :four
    | :five
    | :six
    | :seven
    | :eight

  @type column :: :b
    | :b
    | :c
    | :d
    | :e
    | :f
    | :g

  @type coordinate :: {row, column}

  @type duelist :: %{
    name: String.t,
    color: color,
    ip: {number, number, number, number},
    port: number,
    tcp_port: port
  }

  @type piece :: %{
    color: color,
    rules: number
  }

  @type pieces :: {:king, piece}
    | {:queen, piece}
    | {:rook, piece}
    | {:bishop, piece}
    | {:knight, piece}
    | {:pawn, piece}

  @type tile :: %{
    piece: {:some, pieces} | :none,
    color: color,
    selected_by: {:some, color} | :none,
    conquerable_by: {:some, color} | :none
  }

  @type tiles :: %{
    optional(row) => %{
      optional(column) => tile
    }
  }

  @type board :: %{
    tiles: tiles
  }

  @type duel :: %Duel{
    id: String.t,
    duelists: [duelist],
    board: board,
    rules: ChessPlus.Well.Rules.rules
  }

  defstruct id: "",
    duelists: [],
    board: %{},
    rules: []

  @impl(Guardian.Secret)
  def make_initial_state(id) do
    %Duel{id: id}
  end

  defmodule Row do
    import ChessPlus.Result, only: [retn: 1]
    @type result :: ChessPlus.Result.result
    @type row :: ChessPlus.Well.Duel.row

    @spec to_num(row) :: result
    def to_num(:one), do: 1 |> retn
    def to_num(:two), do: 2 |> retn
    def to_num(:three), do: 3 |> retn
    def to_num(:four), do: 4 |> retn
    def to_num(:five), do: 5 |> retn
    def to_num(:six), do: 6 |> retn
    def to_num(:seven), do: 7 |> retn
    def to_num(:eight), do: 8 |> retn
    def to_num(x), do: {:error, "Column not found while attempting to convert to number: " <> Atom.to_string(x)}

    @spec from_num(number) :: result
    def from_num(1), do: :one |> retn
    def from_num(2), do: :two |> retn
    def from_num(3), do: :three |> retn
    def from_num(4), do: :four |> retn
    def from_num(5), do: :five |> retn
    def from_num(6), do: :six |> retn
    def from_num(7), do: :seven |> retn
    def from_num(8), do: :eight |> retn
    def from_num(x), do: {:error, "Column not found while attempting to convert to number: " <> x}
  end

  defmodule Column do
    import ChessPlus.Result, only: [retn: 1]
    @type result :: ChessPlus.Result.result
    @type column :: ChessPlus.Well.Duel.column

    @spec to_num(column) :: result
    def to_num(:a), do: 1 |> retn
    def to_num(:b), do: 2 |> retn
    def to_num(:c), do: 3 |> retn
    def to_num(:d), do: 4 |> retn
    def to_num(:e), do: 5 |> retn
    def to_num(:f), do: 6 |> retn
    def to_num(:g), do: 7 |> retn
    def to_num(:h), do: 8 |> retn
    def to_num(x), do: {:error, "Column not found while attempting to convert to number: " <> Atom.to_string(x)}

    @spec from_num(number) :: result
    def from_num(1), do: :a |> retn
    def from_num(2), do: :b |> retn
    def from_num(3), do: :c |> retn
    def from_num(4), do: :d |> retn
    def from_num(5), do: :e |> retn
    def from_num(6), do: :f |> retn
    def from_num(7), do: :g |> retn
    def from_num(8), do: :h |> retn
    def from_num(x), do: {:error, "No column found while attempting to convert from number: " <> x}
  end

  defmodule Duelist do
    alias ChessPlus.Well.Player

    @type duelist :: ChessPlus.Well.Duel.duelist
    @type color :: ChessPlus.Well.Duel.color

    @spec from_player(Player.player) :: duelist
    def from_player(%{name: name, ip: ip, port: port, tcp_port: tcp_port}) do
      %{name: name, ip: ip, port: port, tcp_port: tcp_port, color: :black}
    end

    @spec to_player(duelist) :: Player.player
    def to_player(%{name: name, ip: ip, port: port, tcp_port: tcp_port}) do
      %Player{name: name, ip: ip, port: port, tcp_port: tcp_port}
    end

    @spec with_color(duelist, color) :: duelist
    def with_color(duelist, color) do
      %{duelist | color: color}
    end
  end

  def update_duel(%{duel: {:some, id}}, update) do
    {:ok, Duel.update(id, update)}
  end

  def update_duel(_), do: {:error, "Player not joined a duel"}

  def update_board(%{duel: {:some, _}} = sender, update) do
    update_duel(sender, fn duel -> %{duel | board: update.(duel.board)} end)
  end

  def update_board(%Duel{id: id, board: board}, update) do
    Duel.update(id, &%{&1 | board: update.(board)})
  end

  @spec update_tile(sender | duel, coordinate, (tile -> tile)) :: Result.result
  def update_tile(%{duel: {:some, _}} = sender, {row, col}, update) do
    update_board(sender, fn board ->
      %{board | tiles: Matrix.update(board.tiles, row, col, update)}
    end)
  end

  def update_tile(%Duel{id: _} = duel, {row, col}, update) do
    update_board(duel, fn board -> %{board | tiles: Matrix.update(board.tiles, row, col, update)} end)
  end

  def update_tile_where(%{duel: {:some, _}} = sender, predicate, update) do
    update_board(sender, fn board ->
      %{board | tiles: Matrix.update_where(board.tiles, predicate, update)}
    end)
  end

  def update_tile_where(%Duel{id: _} = duel, predicate, update) do
    update_board(duel, fn board ->
      %{board | tiles: Matrix.update_where(board.tiles, predicate, update)}
    end)
  end

  def map_duelists(%{duel: {:some, id}}, update) do
    map_duelists(Duel.fetch(id), update)
  end

  def map_duelists(duel, update) do
    Enum.map(duel.duelists, update)
  end

  def map_opponent(%{duel: {:some, id}} = sender, update) do
    map_opponent(Duel.fetch(id), update, sender)
  end

  def map_opponent(duel, update, sender) do
    Enum.filter(duel.duelists, fn %{name: name} -> name != sender.name end)
    |> Enum.map(update)
  end

  def map_player(%{duel: {:some, id}} = sender, update) do
    map_player(Duel.fetch(id), update, sender)
  end

  def map_player(x, y) do
    ChessPlus.Logger.log x
    ChessPlus.Logger.log y
  end

  def map_player(duel, update, sender) do
    ChessPlus.Logger.log "map_player"
    ChessPlus.Logger.log duel.duelists
    Enum.find(duel.duelists, fn %{name: name} -> name == sender.name end)
    |> update.()
  end

  def is_player?(%{duel: {:some, id}} = player, color) do
    Duel.fetch(id)
    |> is_player?(color, player)
  end

  def is_player?(duel, color, sender) do
    map_player(duel, fn player -> player.color == color end, sender)
  end

  def tst(), do: true

end
