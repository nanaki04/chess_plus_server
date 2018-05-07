defmodule ChessPlus.StartDuelTest do
  use ExUnit.Case, async: false

  @login_wave_dto %{"Location" => %{"Domain" => "player", "Invocation" => "join"}, "Name" => "Sheep"}
  @start_duel_dto %{"Location" => %{"Domain" => "duel", "Invocation" => "new"}, "Map" => "Classic"}

  test "can start a duel" do
    {:ok, login_json} = Poison.encode(@login_wave_dto)
    {:ok, start_duel_json} = Poison.encode(@start_duel_dto)
    {:ok, udp} = :gen_udp.open(4002)
    {:ok, tcp} = :gen_tcp.connect('127.0.0.1', 1338, [:binary])
    :gen_udp.send(udp, '127.0.0.1', 1337, login_json)
    receive do
      {:udp, _socket, ip, port, wave} ->
        :gen_tcp.send(tcp, login_json <> "\n")
        receive do
          {:udp, _socket, ip, port, wave} ->
            :gen_udp.send(udp, '127.0.0.1', 1337, start_duel_json)
            receive do
              {:tcp, _, msg} ->
                ChessPlus.Logger.log(msg)
              msg ->
                ChessPlus.Logger.warn(msg)
            after
              5000 ->
                ChessPlus.Logger.warn("Start duel timed out")
            end
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
