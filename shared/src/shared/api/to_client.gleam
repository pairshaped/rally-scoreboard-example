//// Root API messages emitted by the server to browser clients.
////
//// Receivers on each Mount decide which page messages should be produced
//// when these values arrive over the shared ToClient transport lane.

import shared/api/domain/game.{
  type AdminGameDetail, type AdminGameSummary, type GameDetail,
  type GameScoreUpdate, type PublicGameSummary,
}
import shared/api/domain/standing.{type PowerRankingRow, type StandingRow}

pub type ToClient {
  GamesLoaded(games: List(PublicGameSummary))
  GameLoaded(game: GameDetail)
  StandingsLoaded(rows: List(StandingRow))
  PowerRankingsLoaded(rows: List(PowerRankingRow))
  GameScoreUpdated(update: GameScoreUpdate)
  StandingsUpdated(rows: List(StandingRow))
  GamesLoadFailed(reason: String)
  AdminGamesLoaded(games: List(AdminGameSummary))
  GameCreated(game: AdminGameDetail)
  ScoreUpdateSaved(game: AdminGameDetail)
  ResultSaved(game: AdminGameDetail)
  AdminError(reason: String)
}
