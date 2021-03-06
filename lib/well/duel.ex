defmodule ChessPlus.Well.Duel do
  use ChessPlus.Well
  alias ChessPlus.Matrix
  alias ChessPlus.Result
  alias ChessPlus.Well.Rules
  alias ChessPlus.Option
  alias __MODULE__, as: Duel

  @vsn "0"

  @type territory :: :classic
    | :debug

  @type color :: :black | :white

  @type row :: :one
    | :two
    | :three
    | :four
    | :five
    | :six
    | :seven
    | :eight
    | :nine
    | :ten
    | :eleven
    | :twelve

  @type column :: :b
    | :b
    | :c
    | :d
    | :e
    | :f
    | :g
    | :h
    | :i
    | :j
    | :k
    | :l

  @type coordinate :: {row, column}

  @type rule :: Rules.rule

  @type buff_type :: {:add_rule, %{rules: [number]}}

  @type buff_duration :: {:turn, number}

  @type buff :: %{
    id: number,
    type: buff_type,
    duration: buff_duration
  }

  @type active_buff :: %{
    id: number,
    type: buff_type,
    duration: buff_duration,
    piece_id: number
  }

  @type buffs :: %{
    active_buffs: [active_buff],
    buffs: %{number => buff}
  }

  @type duelist :: %{
    name: String.t,
    color: color,
    ip: {number, number, number, number},
    port: number,
    tcp_port: port
  }

  @type piece :: %{
    color: color,
    rules: [number],
    move_count: number,
    id: id
  }

  @type piece_type :: :king
    | :queen
    | :rook
    | :bishop
    | :knight
    | :pawn

  @type piece_template :: {piece_type, %{
    color: color,
    rules: [number],
  }}

  @type pieces :: {piece_type, piece}

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

  @type duel_state :: {:turn, :black}
    | {:turn, :white}
    | {:turn, :any}
    | :paused
    | {:ended, :remise}
    | {:ended, {:win, :black}}
    | {:ended, {:win, :white}}
    | {:ended, {:request_rematch, :black}}
    | {:ended, {:request_rematch, :white}}

  @type duel :: %Duel{
    id: String.t,
    duelists: [duelist],
    board: board,
    rules: ChessPlus.Well.Rules.rules,
    win_conditions: [ChessPlus.Well.Rules.rule],
    duel_state: duel_state,
    piece_templates: %{black: [piece_template], white: [piece_template]},
    buffs: buffs
  }

  defstruct id: "",
    duelists: [],
    board: %{},
    rules: %{},
    win_conditions: [],
    duel_state: :paused,
    piece_templates: %{black: [], white: []},
    buffs: %{
      active_buffs: [],
      buffs: []
    }

  @impl(Guardian.Secret)
  def make_initial_state(id) do
    %Duel{id: id}
  end

  defmodule Color do
    @type color :: ChessPlus.Well.Duel.color

    @spec inverse(color) :: color
    def inverse(:white), do: :black
    def inverse(:black), do: :white
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
    def to_num(:nine), do: 9 |> retn
    def to_num(:ten), do: 10 |> retn
    def to_num(:eleven), do: 11 |> retn
    def to_num(:twelve), do: 12 |> retn
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
    def from_num(9), do: :nine |> retn
    def from_num(10), do: :ten |> retn
    def from_num(11), do: :eleven |> retn
    def from_num(12), do: :twelve |> retn
    def from_num(x), do: {:error, "Column not found while attempting to convert to number: " <> to_string(x)}
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
    def to_num(:i), do: 9 |> retn
    def to_num(:j), do: 10 |> retn
    def to_num(:k), do: 11 |> retn
    def to_num(:l), do: 12 |> retn
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
    def from_num(9), do: :i |> retn
    def from_num(10), do: :j |> retn
    def from_num(11), do: :k |> retn
    def from_num(12), do: :l |> retn
    def from_num(x), do: {:error, "No column found while attempting to convert from number: " <> to_string(x)}
  end

  defmodule Coordinate do
    alias ChessPlus.Well.Duel
    alias ChessPlus.Well.Duel.Row
    alias ChessPlus.Well.Duel.Column
    alias ChessPlus.Result
    import ChessPlus.Result, only: [<~>: 2, ~>>: 2]

    @type t :: Duel.coordinate

    @spec from_num({number, number}) :: Result.result
    def from_num({x, y}) do
      {:ok, &{&1, &2}}
      <~> Row.from_num(x)
      <~> Column.from_num(y)
    end

    @spec to_num(t) :: Result.result
    def to_num({row, column}) do
      {:ok, &{&1, &2}}
      <~> Row.to_num(row)
      <~> Column.to_num(column)
    end

    @spec find_offset(t, t) :: Result.result
    def find_offset({row1, col1}, {row2, col2}) do
      {:ok, &{&3 - &1, &4 - &2}}
      <~> Row.to_num(row1)
      <~> Column.to_num(col1)
      <~> Row.to_num(row2)
      <~> Column.to_num(col2)
    end

    @spec apply_offset(t | Option.option, {number, number}) :: Result.result | Option.option
    def apply_offset({:some, coord}, offset) do
      apply_offset(coord, offset)
      |> Option.from_result()
    end

    def apply_offset({row, col}, {x, y}) do
      ({:ok, &{&1 + x, &2 + y}}
      <~> Row.to_num(row)
      <~> Column.to_num(col))
      ~>> &from_num/1
    end

    def apply_offset(:none, _), do: :none
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

  defmodule Piece do
    alias ChessPlus.Option
    alias ChessPlus.Result
    import ChessPlus.Option, only: [<|>: 2]

    @type pieces :: ChessPlus.Well.Duel.pieces
    @type piece :: ChessPlus.Well.Duel.piece
    @type piece_type :: ChessPlus.Well.Duel.piece_type
    @type piece_template :: ChessPlus.Well.Duel.piece_template
    @type color :: ChessPlus.Well.Duel.color
    @type duel :: ChessPlus.Well.Duel.duel
    @type duelist :: ChessPlus.Well.Duel.duelist
    @typep state :: duel
      | duelist
      | [pieces]

    @spec map(pieces, (piece -> piece)) :: pieces
    def map({type, content}, update) do
      {type, update.(content)}
    end

    @spec id(pieces | Option.option) :: Option.option
    def id({_, %{id: id}}), do: {:some, id}
    def id({:some, {_, %{id: id}}}), do: {:some, id}
    def id(_), do: :none

    @spec type_to_rank(piece_type) :: Result.result
    def type_to_rank(:pawn), do: {:ok, 1}
    def type_to_rank(:knight), do: {:ok, 2}
    def type_to_rank(:bishop), do: {:ok, 3}
    def type_to_rank(:rook), do: {:ok, 4}
    def type_to_rank(:queen), do: {:ok, 5}
    def type_to_rank(:king), do: {:ok, 6}
    def type_to_rank(t), do: {:error, "No such piece type: " <> to_string(t)}

    @spec rank_to_type(number) :: Result.result
    def rank_to_type(1), do: {:ok, :pawn}
    def rank_to_type(2), do: {:ok, :knight}
    def rank_to_type(3), do: {:ok, :bishop}
    def rank_to_type(4), do: {:ok, :rook}
    def rank_to_type(5), do: {:ok, :queen}
    def rank_to_type(6), do: {:ok, :king}
    def rank_to_type(r), do: {:error, "No piece type for rank: " <> to_string(r)}

    @spec find_template(duel, color, piece_type) :: Option.option
    def find_template(%Duel{} = duel, color, piece_type) do
      Enum.find(duel.piece_templates[color], fn
        {^piece_type, _} -> true
        _ -> false
      end)
      |> Option.from_nullable()
      |> Option.map(fn {_, template} -> template end)
    end

    @spec merge_template(pieces | Option.option, piece_template) :: pieces | Option.option
    def merge_template({:some, piece}, piece_template), do: {:some, merge_template(piece, piece_template)}
    def merge_template(:none, _), do: :none
    def merge_template({_, piece}, {piece_type, %{color: color, rules: rules}}) do
      {piece_type, %{piece | color: color, rules: rules}}
    end

    @spec find_by_type(state, atom) :: [pieces]
    def find_by_type(%{duel: {:some, id}}, piece_type) do
      find_by_type(Duel.fetch(id), piece_type)
    end

    def find_by_type(%Duel{} = duel, piece_type) do
      Duel.fetch_piece_where(duel, fn
        {:some, {type, _}} -> type == piece_type
        {type, _} -> type == piece_type
        _ -> false
      end)
      |> Enum.map(&Option.unlift/1)
    end

    def find_by_type(pieces, piece_type) do
      Enum.filter(pieces, fn {type, _} -> type == piece_type end)
    end

    @spec find_by_color(state, color) :: [pieces]
    def find_by_color(%{duel: {:some, id}}, color) do
      find_by_color(Duel.fetch(id), color)
    end

    def find_by_color(%Duel{} = duel, color) do
      Duel.fetch_piece_where(duel, fn
        {:some, {_, %{color: c}}} -> color == c
        {_, %{color: c}} -> color == c
        _ -> false
      end)
      |> Enum.map(&Option.unlift/1)
    end

    def find_by_color(pieces, color) do
      Enum.filter(pieces, fn
        {:some, {_, %{color: c}}} -> color == c
        {_, %{color: c}} -> color == c
        _ -> false
      end)
      |> Enum.map(&Option.unlift/1)
    end

    @spec find_by_type_and_color(state, atom, color) :: [pieces]
    def find_by_type_and_color(state, type, color) do
      find_by_type(state, type)
      |> find_by_color(color)
    end

    def find_first([piece | _]), do: {:some, piece}
    def find_first([]), do: :none

    def find_black_king(state) do
      find_by_type_and_color(state, :king, :black)
      |> find_first()
    end

    def find_white_king(state) do
      find_by_type_and_color(state, :king, :white)
      |> find_first()
    end

    @spec find_piece_coordinate(duel, pieces) :: Option.option
    def find_piece_coordinate(%Duel{} = duel, {_, piece}) do
      Matrix.find_r_c(duel.board.tiles, fn
        _, _, %{piece: {:some, {_, p}}} -> piece.id == p.id
        _, _, _ -> false
      end)
      <|> fn {row, column, _} -> {row, column} end
    end

    def find_piece_coordinate(%Duel{}, _), do: :none

    @spec find_piece_types(duel) :: [piece_type]
    def find_piece_types(%Duel{} = duel) do
      Matrix.map(duel.board.tiles, fn
        %{piece: {:some, {piece_type, _}}} -> {:some, piece_type}
        _ -> :none
      end)
      |> Matrix.items()
      |> Enum.flat_map(&(&1))
      |> Option.unwrap()
      |> Option.or_else([])
      |> Enum.uniq()
    end
  end

  defmodule Buff do
    alias ChessPlus.Well.Duel
    alias ChessPlus.Option
    alias ChessPlus.Result

    @type buff :: Duel.buff
    @type buff_type :: Duel.buff_type
    @type buff_duration :: Duel.buff_duration
    @type active_buff :: Duel.active_buff
    @type buffs :: Duel.buffs
    @type duel :: ChessPlus.Well.Duel.duel

    @spec find_buff(duel, number) :: Option.option
    def find_buff(%Duel{} = duel, id) do
      duel.buffs.buffs[id]
      |> Option.from_nullable()
    end

    @spec find_active_buff(duel, number) :: Option.option
    def find_active_buff(%Duel{} = duel, id) do
      Enum.find(duel.buffs.active_buffs, fn
        %{id: ^id} -> true
        _ -> false
      end)
      |> Option.from_nullable()
    end

    @spec find_active_buffs_by_piece_id(duel, number) :: [active_buff]
    def find_active_buffs_by_piece_id(%Duel{} = duel, piece_id) do
      Enum.filter(duel.buffs.active_buffs, fn
        %{piece_id: ^piece_id} -> true
        _ -> false
      end)
    end

    @spec find_rules_added_by_buffs(duel, number) :: [number]
    def find_rules_added_by_buffs(%Duel{} = duel, piece_id) do
      Enum.filter(duel.buffs.active_buffs, fn
        %{piece_id: ^piece_id, type: {:add_rule, %{rules: _}}} -> true
        _ -> false
      end)
      |> Enum.flat_map(fn %{type: {_, %{rules: rules}}} -> rules end)
    end

    @spec update_buffs(duel, fun) :: Result.result
    def update_buffs(%Duel{} = duel, update) do
      %{duel | buffs: update.(duel.buffs)}
      |> Result.retn()
    end

    @spec update_active_buffs(duel, fun) :: Result.result
    def update_active_buffs(%Duel{} = duel, update) do
      update_buffs(duel, fn buffs -> %{buffs | active_buffs: update.(buffs.active_buffs)} end)
    end

    @spec add_buff(duel, number, number) :: Result.result
    def add_buff(%Duel{} = duel, buff_id, piece_id) do
      find_buff(duel, buff_id)
      |> Option.map(fn buff -> Map.put(buff, :piece_id, piece_id) end)
      |> Option.to_result("Buff to add not found")
      |> Result.bind(fn buff -> update_active_buffs(duel, &[buff | &1]) end)
    end

    @spec remove_buff(duel, number) :: Result.result
    def remove_buff(%Duel{} = duel, id) do
      update_active_buffs(duel, fn buffs ->
        Enum.filter(buffs, fn
          %{id: ^id} -> false
          _ -> true
        end)
      end)
    end

    @spec remove_expired_buffs(duel) :: Result.result
    def remove_expired_buffs(%Duel{} = duel) do
      update_active_buffs(duel, fn buffs ->
        Enum.filter(buffs, fn
          %{duration: {:turn, duration}} -> duration >= 0
          _ -> true
        end)
      end)
    end

    @spec decrement_turn_durations(duel) :: Result.result
    def decrement_turn_durations(%Duel{} = duel) do
      update_active_buffs(duel, fn buffs ->
        Enum.map(buffs, fn
          %{duration: {:turn, duration}} = buff -> %{buff | duration: {:turn, duration - 1}}
          buff -> buff
        end)
      end)
    end

  end

  def update_duel(%{duel: {:some, id}}, update) do
    {:ok, Duel.update!(id, update)}
  end

  def update_duel(_), do: {:error, "Player not joined a duel"}

  def update_board(%{duel: {:some, _}} = sender, update) do
    update_duel(sender, fn duel -> %{duel | board: update.(duel.board)} end)
  end

  def update_board(%Duel{board: board} = duel, update) do
    {:ok, %{duel | board: update.(board)}}
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

  def fetch_tile(%Duel{} = duel, {row, col}) do
    Matrix.fetch(duel.board.tiles, row, col)
    |> Option.from_result()
  end

  def has_tile?(%Duel{} = duel, {:some, coord}), do: has_tile?(duel, coord)
  def has_tile?(_, :none), do: false

  def has_tile?(%Duel{} = duel, coord) do
    fetch_tile(duel, coord)
    |> Option.to_bool()
  end

  def has_tiles?(%Duel{} = duel, tiles) do
    Enum.all?(tiles, fn t -> has_tile?(duel, t) end)
  end

  def move_piece(%Duel{id: _} = duel, {from_row, from_col} = from, to) do
    piece = Matrix.fetch(duel.board.tiles, from_row, from_col)
    |> Option.from_result()
    |> Option.bind(fn tile -> tile.piece end)

    update_tile(duel, from, fn tile -> %{tile | piece: :none} end)
    |> Result.bind(fn duel -> update_tile(duel, to, fn tile -> %{tile | piece: piece} end) end)
  end

  def update_piece_where(%Duel{id: _} = duel, predicate, update) do
    update_tile_where(
      duel,
      fn %{piece: piece} -> predicate.(piece) end,
      fn %{piece: piece} = tile ->
        if predicate.(piece) do
          Map.update(tile, :piece, :none, update)
        else
          tile
        end
      end
    )
  end

  def update_piece_by_id(%Duel{} = duel, id, update) do
    update_piece_where(duel, fn
      {:some, {_, %{id: ^id}}} -> true
      _ -> false
    end, update)
  end

  def update_piece(%Duel{} = duel, coord, update) do
    update_tile(duel, coord, fn tile ->
      Map.update(tile, :piece, :none, update)
    end)
  end

  def increment_piece_move_count(%Duel{} = duel, coord) do
    update_piece(duel, coord, fn
      :none -> :none
      {:some, piece} -> {:some, Piece.map(piece, fn p ->  Map.update(p, :move_count, 1, &(&1 + 1)) end)}
    end)
  end

  def fetch_piece_where(%Duel{id: _} = duel, predicate) do
    Matrix.reduce(duel.board.tiles, [], fn _, _, tile, acc ->
      if predicate.(tile.piece), do: [tile.piece | acc], else: acc
    end)
  end

  def fetch_piece_by_id(%Duel{} = duel, id) do
    fetch_piece_where(duel, fn
      {:some, {_, %{id: piece_id}}} -> piece_id == id
      _ -> false
    end)
    |> Option.from_list()
    |> Option.bind(&Kernel.hd/1)
  end

  def fetch_piece(%Duel{} = duel, coord) do
    fetch_tile(duel, coord)
    |> Option.bind(fn tile -> tile.piece end)
  end

  def fetch_rules(%Duel{rules: rules}), do: rules

  def fetch_rules(%{duel: {:some, id}}) do
    fetch(id)
    |> fetch_rules()
  end

  def fetch_piece_rules(%Duel{} = duel, {_, %{id: id, rules: rules}}) do
    rules = rules ++ ChessPlus.Well.Duel.Buff.find_rules_added_by_buffs(duel, id)
    fetch_rules(duel)
    |> Rules.find_rules(rules)
  end

  def fetch_piece_rules(%{duel: {:some, id}}, piece) do
    fetch(id)
    |> fetch_piece_rules(piece)
  end

  def fetch_piece_rules(%Duel{} = duel, {_, %{rules: rules}}, rule_type) do
    fetch_rules(duel)
    |> Rules.find_rules(rules, rule_type)
  end

  def fetch_piece_rules(%{duel: {:some, id}}, piece, rule_type) do
    fetch(id)
    |> fetch_piece_rules(piece, rule_type)
  end

  @spec find_rules_targetting_coord(duel, coordinate, pieces) :: [Rules.rule]
  def find_rules_targetting_coord(%Duel{} = duel, coordinate, piece) do
    with rules <- fetch_piece_rules(duel, piece),
         {:some, piece_coordinate} <- Duel.Piece.find_piece_coordinate(duel, piece)
    do
      offset = Duel.Coordinate.find_offset(piece_coordinate, coordinate)

      Enum.filter(rules, fn
        {:move, %{offset: rule_offset}} -> offset == {:ok, rule_offset}
        {:conquer, %{offset: rule_offset}} -> offset == {:ok, rule_offset}
        {:move_combo, %{my_movement: rule_offset}} -> offset == {:ok, rule_offset}
        {:conquer_combo, %{my_movement: rule_offset}} -> offset == {:ok, rule_offset}
        _ -> false
      end)
    else
      []
    end
  end

  @spec find_rule_target_coord(duel, Rules.rule, Option.option) :: Option.option
  def find_rule_target_coord(%Duel{} = duel, {_, %{offset: offset}}, {:some, piece}) do
    Duel.Piece.find_piece_coordinate(duel, piece)
    |> Option.bind(fn coord ->
      Duel.Coordinate.apply_offset(coord, offset)
      |> Option.from_result()
    end)
  end
  def find_rule_target_coord(%Duel{} = duel, {_, %{target_offset: offset}}, {:some, piece}) do
    Duel.Piece.find_piece_coordinate(duel, piece)
    |> Option.bind(fn coord ->
      Duel.Coordinate.apply_offset(coord, offset)
      |> Option.from_result()
    end)
  end
  def find_rule_target_coord(_, _, _), do: :none

  def find_rule_target(%Duel{} = duel, rule, piece) do
    find_rule_target_coord(duel, rule, piece)
    |> Option.bind(fn coord -> fetch_piece(duel, coord) end)
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

  def map_player(duel, update, sender) do
    Enum.find(duel.duelists, fn %{name: name} -> name == sender.name end)
    |> update.()
  end

  def fetch_player(duel, sender) do
    case Enum.find(duel.duelists, fn %{name: name} -> name == sender.name end) do
      nil -> :none
      duelist -> {:some, duelist}
    end
  end

  def remove_player(duel, %{name: name}) do
    %{duel | duelists: Enum.filter(duel.duelists, fn duelist -> duelist.name != name end)}
  end

  def is_full?(duel_id) when is_binary(duel_id) do
    Duel.fetch(duel_id)
    |> is_full?()
  end

  def is_full?(duel) do
    length(duel.duelists) > 1
  end

  def is_player?(%{duel: {:some, id}} = player, color) do
    Duel.fetch(id)
    |> is_player?(color, player)
  end

  def is_player?(duel, color, sender) do
    map_player(duel, fn player -> player.color == color end, sender)
  end

  def fetch_player_color(duel, sender) do
    fetch_player(duel, sender)
    |> Option.map(fn %{color: color} -> color end)
  end

  def update_duel_state(duel, updater) when is_function(updater, 1) do
    %Duel{duel | duel_state: updater.(duel.duel_state)}
  end

  def update_duel_state(duel, state) do
    %Duel{duel | duel_state: state}
  end

end
