//// Team domain types used across the shared API wire boundary.
////
//// TeamDetail is the payload for a single-team page. It carries team identity,
//// a current win/loss record, and the team's most recent public game summaries.
//// Derived from the Generator Framework's shared API domain contract.

import shared/api/domain/game.{type PublicGameSummary}

pub type TeamDetail {
  TeamDetail(
    code: String,
    name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
    recent_games: List(PublicGameSummary),
  )
}
