//// Public server handler for a single team page.
////
//// Looks up a team by its URL slug, computes its record from final games,
//// and loads the team's recent games.
////
//// Generated public dispatch and SSR both call `load` to produce the page's
//// ToClient result. Route params are extracted from request_context.route.

import generated/public/request_context.{type RequestContext}
import generated/public/route
import generated/sql/server/games_sql
import generated/sql/server/teams_sql
import gleam/list
import gleam/option
import server/helpers/db
import server/public/pages/games as games_page
import server/server_context.{type ServerContext}
import shared/api/domain/game.{type PublicGameSummary}
import shared/api/domain/team.{type TeamDetail, TeamDetail}
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load(
  request_context request_context: RequestContext,
  server_context context: ServerContext,
) -> ToClient {
  case request_context.route {
    route.Team(slug) ->
      case team_detail(context.db, slug:) {
        Ok(detail) -> to_client.TeamLoaded(team: detail)
        Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
      }
    _ -> to_client.GamesLoadFailed(reason: "unexpected route for team")
  }
}

fn team_detail(
  db: sqlight.Connection,
  slug slug: String,
) -> Result(TeamDetail, db.QueryError) {
  case teams_sql.get_team_by_slug(db:, slug:) {
    Ok([row, ..]) -> {
      let code = option.unwrap(row.code, "")
      let recent = case recent_games(db, code:) {
        Ok(games) -> games
        Error(_) -> []
      }
      Ok(TeamDetail(
        code:,
        name: row.name,
        slug: row.slug,
        wins: row.wins,
        losses: row.losses,
        points_for: row.points_for,
        points_against: row.points_against,
        recent_games: recent,
      ))
    }
    Ok([]) -> Error(db.NotFound("no team found for slug"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn recent_games(
  db: sqlight.Connection,
  code code: String,
) -> Result(List(PublicGameSummary), db.QueryError) {
  case games_sql.list_public_games(db:, team_filter: code) {
    Ok(rows) -> Ok(list.map(rows, games_page.game_summary_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}
