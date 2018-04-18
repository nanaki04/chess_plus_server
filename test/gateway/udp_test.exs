defmodule ChessPlus.Gateway.UdpTest do
  use ExUnit.Case
  doctest ChessPlus.Gateway.Udp

  test "can process messages" do
    {:ok, client} = :gen_udp.open(4001)
    assert :ok = :gen_udp.send(client, '127.0.0.1', 1337, "hi lol!")
  end
end
