//// Public server handlers for standings.
////
//// The generated dispatch calls `load_standings` — the snake_case form of the
//// LoadStandings ToServer constructor. Page-data handlers like this return
//// ToClient directly so the dispatch can wrap the result without changing
//// backend model.

import generated/public/request_context.{type RequestContext}
import generated/sql/server/standings_sql
import gleam/list
import server/helpers/db
import server/helpers/domain
import server/server_context.{type ServerContext}
import shared/api/domain/standing
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_standings(
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
) -> ToClient {
  case standings(context.db) {
    Ok(rows) -> to_client.StandingsLoaded(rows:)
    Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
  }
}

fn standings(
  db: sqlight.Connection,
) -> Result(List(standing.StandingRow), db.QueryError) {
  case standings_sql.list_standings(db:) {
    Ok(rows) -> Ok(list.map(rows, domain.standing_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}
