import gleam/dynamic/decode
import gleam/option.{type Option}
import sqlight

/// Generated from src/server/sql/standings/list_standings.sql
pub type ListStandingsRow {
  ListStandingsRow(
    team_code: Option(String),
    team_name: String,
    team_slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}

/// Generated from src/server/sql/standings/list_standings.sql
pub fn list_standings(
  db db: sqlight.Connection,
) -> Result(List(ListStandingsRow), sqlight.Error) {
  sqlight.query(
    "WITH team_games AS ( SELECT home_code AS team_code, home_score AS points_for, away_score AS points_against, CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS win, CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS loss FROM games WHERE final = 1 UNION ALL SELECT away_code AS team_code, away_score AS points_for, home_score AS points_against, CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS win, CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS loss FROM games WHERE final = 1 ) SELECT t.code AS team_code, t.name AS team_name, t.slug AS team_slug, COALESCE(SUM(team_games.win), 0) AS wins, COALESCE(SUM(team_games.loss), 0) AS losses, COALESCE(SUM(team_games.points_for), 0) AS points_for, COALESCE(SUM(team_games.points_against), 0) AS points_against FROM teams AS t LEFT JOIN team_games ON t.code = team_games.team_code GROUP BY t.code, t.name, t.slug ORDER BY wins DESC, points_for DESC, t.code",
    on: db,
    with: [],
    expecting: {
      use team_code <- decode.field(0, decode.optional(decode.string))
      use team_name <- decode.field(1, decode.string)
      use team_slug <- decode.field(2, decode.string)
      use wins <- decode.field(3, decode.int)
      use losses <- decode.field(4, decode.int)
      use points_for <- decode.field(5, decode.int)
      use points_against <- decode.field(6, decode.int)
      decode.success(ListStandingsRow(
        team_code:,
        team_name:,
        team_slug:,
        wins:,
        losses:,
        points_for:,
        points_against:,
      ))
    },
  )
}
