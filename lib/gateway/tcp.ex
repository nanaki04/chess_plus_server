defmodule ChessPlus.Gateway.Tcp do
  alias ChessPlus.Gateway.Hallway
  alias ChessPlus.Dto.Waves, as: WaveDto
  alias ChessPlus.Result
  import ChessPlus.Result, only: [<|>: 2, ~>>: 2]

  use GenServer

  def start_link(_) do
    (GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    <|> fn pid ->
      GenServer.cast(pid, :accept)
      {:ok, pid}
    end)
    |> Result.or_else({:stop, "Failed to initialize tcp socket"})
  end

  def init(:ok) do
    ((:gen_tcp.listen(1338, [:binary, reuseaddr: true])
    |> Result.warn()
    <|> &%{socket: &1, chunks: %{}})
    <|> &Result.retn/1)
    |> Result.or_else({:stop, "Failed to create tcp socket"})
  end

  def terminate(_, %{socket: socket}) do
    :gen_tcp.shutdown(socket, :read_write)
  end

  def handle_info({:tcp, port, chunk}, %{socket: socket, chunks: chunks}) do
    chunks = Map.get_and_update(chunks, port, fn
      nil ->
        case flow_upstream(chunk, port) do
          :done -> :pop
          _ -> {nil, chunk}
        end
      msg ->
        case flow_upstream(msg <> chunk, port) do
          :done -> :pop
          _ -> {msg, msg <> chunk}
        end
    end)
    |> elem(1)

    {:noreply, %{socket: socket, chunks: chunks}}
  end

  def handle_info({:tcp_closed, port}, state) do
    Hallway.flow([{:player, :remove}], {:tcp, %{port: port}})
    |> Result.warn()
    {:noreply, state}
  end

  def handle_info(msg, state) do
    ChessPlus.Logger.log({:tcp_unhandled_message, msg, state})
    {:noreply, state}
  end

  def handle_call(:close, %{socket: socket}) do
    :gen_tcp.close(socket)
  end

  defp flow_upstream(message, port) do
    case String.ends_with?(message, "\n") do
      true ->
        ((Poison.decode(String.slice(message, 0..-2))
        <|> fn
          waves when is_list(waves) ->
            Enum.map(waves, &WaveDto.imprt/1)
          wave ->
            [WaveDto.imprt(wave)]
        end)
        ~>> (&Result.unwrap/1)
        <|> fn waves -> Hallway.flow(waves, {:tcp, %{port: port}}) end)
        |> Result.warn()

        :done
      false ->
        :in_progress
    end
  end

  def handle_call({:send, wave, %{tcp_port: port}}, _, state) do
    ChessPlus.Logger.log(wave)
    File.write("log.json", wave)
    {:reply, :gen_tcp.send(port, wave), state}
  end

  def handle_cast(:accept, %{socket: socket} = state) do
    pid = self()
    Task.start_link(fn ->
      :gen_tcp.accept(socket)
      <|> fn client -> :gen_tcp.controlling_process(client, pid) end
      GenServer.cast(__MODULE__, :accept)
    end)

    {:noreply, state}
  end

  def out(waves, players) do
    (((Enum.map(waves, &WaveDto.export/1)
    |> Result.unwrap()
    <|> fn dtos -> Enum.map(dtos, &Poison.encode/1) end
    ~>> &Result.unwrap/1)
    <|> fn waves -> Enum.map(players, fn player ->
      Enum.map(waves, fn wave ->
        GenServer.call(__MODULE__, {:send, wave <> "\n", player})
      end)
    end) end)
    ~>> &Result.unwrap/1)
    |> Result.warn()
  end

end
