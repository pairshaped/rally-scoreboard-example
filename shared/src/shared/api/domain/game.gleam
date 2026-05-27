//// Shared game domain types for the root API wire graph.
////
//// These custom types can appear in ToServer or ToClient payloads, so their
//// constructors must remain globally unique across the shared API graph.

pub type GameStatus {
  Scheduled
  Live(period: String)
  Final
}

pub type Team {
  Team(code: String, name: String, slug: String)
}

pub type PublicGameSummary {
  PublicGameSummary(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}

pub type GameDetail {
  GameDetail(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
    scoring_summary: List(String),
  )
}

pub type GameScoreUpdate {
  GameScoreUpdate(
    game_id: Int,
    home_score: Int,
    away_score: Int,
    period: String,
    status: GameStatus,
  )
}

pub type AdminGameSummary {
  AdminGameSummary(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
    needs_attention: Bool,
  )
}

pub type AdminGameDetail {
  AdminGameDetail(
    id: Int,
    home_code: String,
    away_code: String,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
    period: String,
  )
}
