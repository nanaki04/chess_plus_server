defmodule ChessPlus.Gateway.Hallway do
  alias ChessPlus.Gateway.Udp
  alias ChessPlus.Gateway.Tcp
  alias ChessPlus.Bridge
  alias ChessPlus.Result
  import ChessPlus.Result, only: [<|>: 2]

  def flow(waves, sender) do
    Task.Supervisor.start_child(ChessPlus.Task.Supervisor, fn ->
      upstream(waves, sender)
      |> downstream(sender)
    end)
  end

  defp upstream(waves, sender) do
    Result.flat_map(waves, fn wave -> Bridge.cross(wave, sender) end)
  end

  defp downstream({:ok, waves}, _) do
    Enum.map(waves, fn
      {:udp, player, wave} -> Udp.out([wave], [player])
      {:tcp, player, wave} -> Tcp.out([wave], [player])
      error -> {:error, "Invalid output"}
    end)
    |> Result.unwrap()
    |> Result.warn()
  end

  defp downstream({:error, error}, {:udp, sender}) do
    Udp.out([{{:global, :error}, error}], [sender])
  end

  defp downstream({:error, error}, {:tcp, sender}) do
    Tcp.out([{{:global, :error}, error}], [sender])
  end
end
