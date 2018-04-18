defmodule ChessPlus.Gateway.Udp do
  alias ChessPlus.Dto.Waves, as: WaveDto
  alias ChessPlus.Result
  alias ChessPlus.Bridge
  import ChessPlus.Result, only: [<|>: 2, ~>>: 2]

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    :gen_udp.open(1337, [:binary])
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
    <|> fn waves -> Enum.map(waves, fn wave -> Bridge.cross(wave, %{ip: ip, port: port}) end) end
    ~>> &Result.unwrap/1)
    |> Result.orElse(&IO.inspect/1)

    {:noreply, state}
  end

  def handle_call({:send, waves, %{ip: ip, port: port}}, _, state) do
    {:reply, :gen_udp.send(state, ip, port, waves), state}
  end

  def out(waves, players) do
    ((Enum.map(waves, &WaveDto.export/1)
    |> Result.unwrap()
    <|> fn dtos -> Enum.map(dtos, &Poison.encode/1) end
    ~>> &Result.unwrap/1)
    <|> fn waves -> Enum.map(players, fn player ->
       GenServer.call(__MODULE__, {:send, waves, player})
    end) end)
    |> Result.orElse(&IO.inspect/1)
  end

end
