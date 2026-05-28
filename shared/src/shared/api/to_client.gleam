//// Root API messages emitted by the server to browser clients.
////
//// ToClient is the server-event vocabulary. Each constructor is applied as a
//// page mini-update: a constructor-named client handler receives the page
//// model plus constructor fields and returns the updated page model plus any
//// page effect. Local page Msg is for browser-originated events only.
////
//// A constructor with multiple active handlers fans out to every matching
//// handler across Mounts.

import shared/api/domain/game.{
  type AdminGameDetail, type AdminGameSummary, type GameDetail,
  type GameScoreUpdate, type PublicGameSummary,
}
import shared/api/domain/standing.{type PowerRankingRow, type StandingRow}
import shared/api/domain/team.{type TeamDetail}

pub type ToClient {
  GamesLoaded(games: List(PublicGameSummary))
  GameLoaded(game: GameDetail)
  StandingsLoaded(rows: List(StandingRow))
  // Exercises same-shape different-constructor wire types alongside StandingsLoaded.
  // No server handler emits this yet; kept as a placeholder for the generator.
  PowerRankingsLoaded(rows: List(PowerRankingRow))
  GameScoreUpdated(update: GameScoreUpdate)
  StandingsUpdated(rows: List(StandingRow))
  GamesLoadFailed(reason: String)
  TeamLoaded(team: TeamDetail)
  AdminGamesLoaded(games: List(AdminGameSummary))
  GameCreated(game: AdminGameDetail)
  ScoreUpdateSaved(game: AdminGameDetail)
  ResultSaved(game: AdminGameDetail)
  AdminError(reason: String)
}
