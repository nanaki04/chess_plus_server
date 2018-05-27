defmodule ChessPlus.Wave do

  @type socket_type :: :tcp | :udp
  @type sender :: ChessPlus.Well.Player.player
  | {:udp, %{ip: {number, number, number, number}, port: number}}
  | {:tcp, %{port: port}}
  @type receiver :: ChessPlus.Well.Player.player | ChessPlus.Well.Duel.duelist
  @type wave :: {{atom, atom}, term}
  | {atom, atom}
  @type wave_downstream :: {socket_type, receiver, wave}
  | {:event, sender, wave}

  @callback flow(wave, sender) :: ChessPlus.Result.result

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
      | {:event, sender, wave}

      @behaviour ChessPlus.Wave

      def flow(_, _), do: {:error, "Flow not implemented for wave"}

      defoverridable [flow: 2]
    end
  end

end
