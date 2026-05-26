//// Shared standings domain types for the root API wire graph.
////
//// Public standings and power-ranking pages use these rows in ToClient
//// payloads emitted by server handlers.

pub type StandingRow {
  StandingRow(
    team_code: String,
    team_name: String,
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
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}
