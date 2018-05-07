defmodule ChessPlus.Bridge do
  alias ChessPlus.Flow
  use PathFinder
  use PathFinder.Footprints

  gatekeeper ChessPlus.Logger.Bridge
  gatekeeper ChessPlus.Bridge.PlayerFinder

  footprints __MODULE__

  footprint :player,
    join: {:self, Flow.Login, :flow, []},
    remove: {:self, Flow.Logout, :flow, []}
  footprint :duel, new: {:self, Flow.InitiateDuel, :flow, []}
  footprint :duelist, join: {:self, Flow.ChallengeDuel, :flow, []} 

  def cross({{domain, invocation}, _} = wave, sender) do
    __MODULE__.follow(domain, invocation, [wave, sender])
  end

  def cross({domain, invocation} = wave, sender) do
    __MODULE__.follow(domain, invocation, [wave, sender])
  end

end
