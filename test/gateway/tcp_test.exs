defmodule ChessPlus.Gateway.TcpTest do
  use ExUnit.Case, async: false
  doctest ChessPlus.Gateway.Tcp

  test "can process messages" do
    {:ok, server} = :gen_tcp.connect({127, 0, 0, 1}, 1338, [:binary])
    assert :ok = :gen_tcp.send(server, "hi lol!\n")
  end
end
