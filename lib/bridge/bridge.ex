defmodule ChessPlus.Bridge do
  alias ChessPlus.Flow
  use PathFinder
  use PathFinder.Footprints

  footprints __MODULE__

  footprint :duelist, join: {:self, Flow.ChallengeDuel, :flow, []} 

  def cross({{domain, invocation}, _} = wave, sender) do
    __MODULE__.follow(domain, invocation, [wave, sender])
  end

end
