defmodule ChessPlus.Bridge do
  alias ChessPlus.Flow
  use PathFinder
  use PathFinder.Footprints

  gatekeeper ChessPlus.Logger.Bridge
  gatekeeper ChessPlus.Bridge.PlayerFinder
  gatekeeper ChessPlus.ObserverRegistry

  footprints __MODULE__

  footprint :player,
    join: {:self, Flow.Login, :flow, []},
    remove: {:self, Flow.Logout, :flow, []}

  footprint :duel,
    new: {:self, Flow.Duel.New, :flow, []}

  footprint :open_duels,
    all: {:self, Flow.FindOpenDuels, :flow, []}

  footprint :duelist,
    join: {:self, Flow.Duel.Join, :flow, []},
    forfeit: {:self, Flow.Duel.Forfeit, :flow, []},
    propose_remise: {:self, Flow.Duel.ProposeRemise, :flow, []},
    remise: {:self, Flow.Duel.AcceptRemise, :flow, []},
    refuse_remise: {:self, Flow.Duel.RefuseRemise, :flow, []}

  footprint :tile,
    select: {:self, Flow.SelectTile, :flow, []},
    deselect: {:self, Flow.DeselectTile, :flow, []}

  footprint :piece,
    move: {:self, Flow.MovePiece, :flow, []}

  def cross({{domain, invocation}, _} = wave, sender) do
    __MODULE__.follow(domain, invocation, [wave, sender])
  end

  def cross({domain, invocation} = wave, sender) do
    __MODULE__.follow(domain, invocation, [wave, sender])
  end

end
