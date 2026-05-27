//// Shared standings domain types for the root API wire graph.
////
//// Public standings and power-ranking pages use these rows in ToClient
//// payloads emitted by server handlers.
////
//// StandingRow and PowerRankingRow intentionally share the same field shape.
//// This exercises a Generator Framework requirement: two wire constructors
//// with identical fields must still be unique plain ETF atoms so the codec
//// can disambiguate them without module path or type identity.

pub type StandingRow {
  StandingRow(
    team_code: String,
    team_name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}

pub type PowerRankingRow {
  PowerRankingRow(
    team_code: String,
    team_name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}
