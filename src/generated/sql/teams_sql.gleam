import gleam/dynamic/decode
import gleam/option.{type Option}
import sqlight

/// Generated from src/sql/teams/get_team_by_slug.sql
pub type GetTeamBySlugRow {
  GetTeamBySlugRow(
    code: Option(String),
    name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
  )
}

/// Generated from src/sql/teams/get_team_by_slug.sql
pub fn get_team_by_slug(
  db db: sqlight.Connection,
  slug slug: String,
) -> Result(List(GetTeamBySlugRow), sqlight.Error) {
  sqlight.query(
    "WITH team_games AS ( SELECT home_code AS team_code, home_score AS points_for, away_score AS points_against, CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS win, CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS loss FROM games WHERE final = 1 UNION ALL SELECT away_code AS team_code, away_score AS points_for, home_score AS points_against, CASE WHEN away_score > home_score THEN 1 ELSE 0 END AS win, CASE WHEN away_score < home_score THEN 1 ELSE 0 END AS loss FROM games WHERE final = 1 ) SELECT t.code, t.name, t.slug, COALESCE(SUM(team_games.win), 0) AS wins, COALESCE(SUM(team_games.loss), 0) AS losses, COALESCE(SUM(team_games.points_for), 0) AS points_for, COALESCE(SUM(team_games.points_against), 0) AS points_against FROM teams AS t LEFT JOIN team_games ON t.code = team_games.team_code WHERE t.slug = :slug GROUP BY t.code, t.name, t.slug",
    on: db,
    with: [sqlight.text(slug)],
    expecting: {
      use code <- decode.field(0, decode.optional(decode.string))
      use name <- decode.field(1, decode.string)
      use slug <- decode.field(2, decode.string)
      use wins <- decode.field(3, decode.int)
      use losses <- decode.field(4, decode.int)
      use points_for <- decode.field(5, decode.int)
      use points_against <- decode.field(6, decode.int)
      decode.success(GetTeamBySlugRow(
        code:,
        name:,
        slug:,
        wins:,
        losses:,
        points_for:,
        points_against:,
      ))
    },
  )
}

/// Generated from src/sql/teams/list_teams.sql
pub type ListTeamsRow {
  ListTeamsRow(code: Option(String), name: String, slug: String)
}

/// Generated from src/sql/teams/list_teams.sql
pub fn list_teams(
  db db: sqlight.Connection,
) -> Result(List(ListTeamsRow), sqlight.Error) {
  sqlight.query(
    "SELECT code, name, slug FROM teams ORDER BY code",
    on: db,
    with: [],
    expecting: {
      use code <- decode.field(0, decode.optional(decode.string))
      use name <- decode.field(1, decode.string)
      use slug <- decode.field(2, decode.string)
      decode.success(ListTeamsRow(code:, name:, slug:))
    },
  )
}
