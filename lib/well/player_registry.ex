defmodule ChessPlus.Well.PlayerRegistry do

  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(id, player_id) do
    name = {:global, id}
    case GenServer.whereis(name) do
      nil ->
        # TODO clean up with a timeout?
        spec = %{id: Agent, start: {Agent, :start_link, [fn -> player_id end, [name: name]]}}
        DynamicSupervisor.start_child(__MODULE__, spec)
      pid ->
        # TODO proper login system
        Agent.update(pid, fn _ -> player_id end)
    end
  end

  @spec terminate_child(term) :: :ok
  def terminate_child(id) do
    case GenServer.whereis({:global, id}) do
      nil -> :ok
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  def get({:udp, %{ip: {n1, n2, n3, n4}, port: port}}) do
    ip = Enum.map([n1, n2, n3, n4], &to_string/1)
    |> Enum.join(".")
    get(ip <> ":" <> to_string(port))
  end

  def get({:tcp, %{port: port}}) do
    get(port)
  end

  def get(id) do
    name = {:global, id}
    case GenServer.whereis(name) do
      nil -> {:error, "Player not logged in"}
      _ -> {:ok, Agent.get(name, fn player_id -> player_id end)}
    end
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

end
