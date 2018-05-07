defmodule ChessPlus.Wave do

  @type socket_type :: :tcp | :udp
  @type sender :: ChessPlus.Well.Player.player
  | {:udp, %{ip: {number, number, number, number}, port: number}}
  | {:tcp, %{port: port}}
  @type receiver :: ChessPlus.Well.Player.player | ChessPlus.Well.Duel.duelist
  @type wave :: {{atom, atom}, term}
  | {atom, atom}
  @type wave_downstream :: {socket_type, receiver, wave}

  defmacro __using__(_) do
    quote do
      @type socket_type :: :tcp | :udp
      @type sender :: ChessPlus.Well.Player.player
      | {:udp, %{ip: {number, number, number, number}, port: number}}
      | {:tcp, %{port: port}}
      @type receiver :: ChessPlus.Well.Player.player | ChessPlus.Well.Duel.duelist
      @type wave :: {{atom, atom}, term}
      | {atom, atom}
      @type wave_downstream :: {socket_type, receiver, wave}
    end
  end

end
