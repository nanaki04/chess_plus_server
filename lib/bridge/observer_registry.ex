defmodule ChessPlus.ObserverRegistry do
  use ChessPlus.Observers

  @observers [
    player_created: [
      ChessPlus.Flow.PlayerRegistry.RegisterPlayer
    ],
    player_deleted: [
      ChessPlus.Flow.PlayerRegistry.UnregisterPlayer,
      ChessPlus.Flow.Duel.LeaveDuel
    ],
    duel_created: [
      ChessPlus.Flow.OpenDuelRegistry.RegisterDuel
    ],
    duel_joined: [
      ChessPlus.Flow.Player.JoinDuel,
      ChessPlus.Flow.OpenDuelRegistry.UnregisterDuel # TODO needs refactoring if more than 2 players per game would be supported
    ],
    duel_left: [
      ChessPlus.Flow.Player.LeaveDuel
    ],
    duel_deleted: [
      ChessPlus.Flow.OpenDuelRegistry.UnregisterDuel
    ],
    piece_moved: [
      ChessPlus.Flow.Piece.UpdatePieceState,
      ChessPlus.Flow.Buff.RefreshBuffs,
      ChessPlus.Flow.Duel.UpdateDuelState,
    ]
  ]
end
