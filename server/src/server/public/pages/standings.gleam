//// Public server handlers for standings.
////
//// Generated public dispatch calls these functions to load official standings
//// and power rankings from final game results.

import generated/public/request_context.{type RequestContext}
import generated/runtime/effect.{type Effect}
import generated/sql/server/games_sql
import gleam/list
import gleam/option.{None, Some}
import server/helpers/db
import server/public/model.{type Model}
import server/server_context.{type ServerContext}
import shared/api/domain/standing
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_standings(
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case standings(context.db) {
    Ok(rows) -> to_client.StandingsLoaded(rows:)
    Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
  }

  #(backend_model, effect.send_to_client(event))
}

fn standings(
  db: sqlight.Connection,
) -> Result(List(standing.StandingRow), db.QueryError) {
  case games_sql.standings(db:) {
    Ok(rows) -> Ok(list.map(rows, standing_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn standing_from_row(row: games_sql.StandingsRow) -> standing.StandingRow {
  let team_code = case row.team_code {
    Some(code) -> code
    None -> ""
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
