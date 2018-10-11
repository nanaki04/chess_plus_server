defmodule ChessPlus.Flow.Login do
  use ChessPlus.Wave
  alias ChessPlus.Well.Player

  # MEMO: udp arrives first
  @impl(ChessPlus.Wave)
  def flow({{:player, :join}, %{name: name}}, {:udp, %{ip: ip, port: port}}) do
    name = find_name(name)

    player = Player.update!(name, fn p -> %Player{
      p |
      name: name,
      ip: ip,
      port: port,
      id: name
    } end)

    {:ok, [
      {:udp, player, {{:player, :created}, player}}
    ]}
  end

  def flow({{:player, :join}, %{name: name}}, {:tcp, %{port: port}}) do
    player = Player.update!(name, fn p -> %Player{
      p |
      name: name,
      tcp_port: port,
      id: name
    } end)

    {:ok, [
      {:event, player, {{:event, :player_created}, player}},
      {:tcp, player, {{:player, :add}, player}}
    ]}
  end

  def flow({{:player, :join}, _}, %Player{}) do
    {:error, "Already logged in"}
  end

  defp find_name(name) do
    if Player.active?(name), do: find_name(add_name_counter(name)), else: name
  end

  @doc """
  ## Examples

    iex> import ChessPlus.Flow.Login
    ...> add_name_counter("Sheep")
    "Sheep(1)"
    ...> add_name_counter("Sheep(1)")
    "Sheep(2)"

  """
  @spec add_name_counter(String.t) :: String.t
  def add_name_counter(name) do
    case Regex.match?(~r/.+\(\d\)(?=$)/, name) do
      false ->
        name <> "(1)"
      true ->
        Regex.replace(~r/\d(?=\)$)/, name, fn x ->
          Integer.parse(x)
          |> elem(0)
          |> Kernel.+(1)
          |> to_string()
        end)
    end
  end

end
