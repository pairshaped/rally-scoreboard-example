//// Shared domain mapping helpers.
////
//// Used by both public and admin server handlers to map database rows
//// into wire-visible domain types. Extracted here so admin code does not
//// need to import public page modules for shared row-to-domain mapping.

import generated/sql/server/games_sql
import gleam/option
import shared/api/domain/game
import shared/api/domain/standing

pub fn game_status(final: Int, period: String) -> game.GameStatus {
  case final {
    1 -> game.Final
    _ -> game.Live(period)
  }
}

pub fn standing_from_row(row: games_sql.StandingsRow) -> standing.StandingRow {
  let team_code = case row.team_code {
    option.Some(code) -> code
    option.None -> ""
  }

  standing.StandingRow(
    team_code:,
    team_name: row.team_name,
    slug: row.team_slug,
    wins: row.wins,
    losses: row.losses,
    points_for: row.points_for,
    points_against: row.points_against,
  )
}
