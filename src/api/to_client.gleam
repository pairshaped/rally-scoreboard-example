//// Root API messages emitted by the server to browser clients.
////
//// ToClient is the server-event vocabulary. Each constructor is applied as a
//// page mini-update: a constructor-named client handler receives the page
//// model plus constructor fields and returns the updated page model plus any
//// page effect. Local page Msg is for browser-originated events only.
////
//// A constructor with multiple active handlers fans out to every matching
//// handler across Mounts.

import api/domain/game.{
  type AdminGameSummary, type GameDetail, type GameSnapshot,
  type PublicGameSummary,
}
import api/domain/standing.{type PowerRankingRow, type StandingRow}
import api/domain/team.{type TeamDetail}

pub type ToClient {
  GamesLoaded(games: List(PublicGameSummary))
  GameLoaded(game: GameDetail)
  StandingsLoaded(rows: List(StandingRow))
  // Exercises same-shape different-constructor wire types alongside StandingsLoaded.
  // No server handler emits this yet; kept as a placeholder for the generator.
  PowerRankingsLoaded(rows: List(PowerRankingRow))
  TeamLoaded(team: TeamDetail)
  AdminGamesLoaded(games: List(AdminGameSummary))
  GameUpdated(game: GameSnapshot)
}
