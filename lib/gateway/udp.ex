defmodule ChessPlus.Gateway.Udp do
  alias ChessPlus.Dto.Waves, as: WaveDto
  alias ChessPlus.Result
  alias ChessPlus.Gateway.Hallway
  import ChessPlus.Result, only: [<|>: 2, ~>>: 2]

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {port, _} = Integer.parse(Application.get_env(:chess_plus_server, :udp_port))
    :gen_udp.open(port, [:binary])
  end

  def handle_info({:udp, _socket, ip, port, waves}, state) do
    ((Poison.decode(waves)
    <|> fn
      waves when is_list(waves) ->
        Enum.map(waves, &WaveDto.imprt/1)
      wave ->
        [WaveDto.imprt(wave)]
    end)
    ~>> fn result -> Result.unwrap(result) end
    <|> fn waves -> Hallway.flow(waves, {:udp, %{ip: ip, port: port}}) end)
    |> Result.warn()

    {:noreply, state}
  end

  def handle_call({:send, wave, %{ip: ip, port: port}}, _, state) do
    ChessPlus.Logger.log(wave)
    {:reply, :gen_udp.send(state, ip, port, wave), state}
  end

  def out(waves, players) do
    (((Enum.map(waves, &WaveDto.export/1)
    |> Result.unwrap()
    <|> fn dtos -> Enum.map(dtos, &Poison.encode/1) end
    ~>> &Result.unwrap/1)
    <|> fn waves -> Enum.map(players, fn player ->
      Enum.map(waves, fn wave ->
        GenServer.call(__MODULE__, {:send, wave, player})
      end)
    end) end)
    ~>> &Result.unwrap/1)
    |> Result.warn()
  end

end
