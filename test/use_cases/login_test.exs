defmodule ChessPlus.LoginTest do
  use ExUnit.Case, async: false

  @login_wave_dto %{"Location" => %{"Domain" => "player", "Invocation" => "join"}, "Name" => "Sheep"}

  test "can login" do
    {:ok, json} = Poison.encode(@login_wave_dto)
    {:ok, udp} = :gen_udp.open(4002)
    {:ok, tcp} = :gen_tcp.connect('127.0.0.1', 1338, [:binary])
    :gen_udp.send(udp, '127.0.0.1', 1337, json)
    receive do
      {:udp, _socket, ip, port, wave} ->
        :gen_tcp.send(tcp, json <> "\n")
        receive do
          {:udp, _socket, ip, port, wave} ->
            assert ip == {127, 0, 0, 1}
            assert port == 1337
            assert wave == '{"Player":{"Name":"Sheep"},"Location":{"Invocation":"add","Domain":"player"}}'
          msg -> ChessPlus.Logger.warn(msg)
        after
          5000 ->
            ChessPlus.Logger.warn("Login timed out")
        end
      msg -> ChessPlus.Logger.warn(msg)
    after
      5000 ->
        ChessPlus.Logger.warn("Create timed out")
    end
  end
end
