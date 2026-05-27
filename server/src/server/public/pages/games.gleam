//// Public server handlers for the games list.
////
//// Generated public dispatch calls these functions to load public game
//// summaries and emit ToClient messages for the public receiver hub.

import generated/public/request_context.{type RequestContext}
import generated/runtime/effect.{type Effect}
import generated/sql/server/games_sql
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import server/helpers/db
import server/helpers/domain
import server/public/model.{type Model}
import server/server_context.{type ServerContext}
import shared/api/domain/game
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_games(
  request_context request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let team_filter = case dict.get(request_context.query, "team") {
    Ok(team) -> Some(team)
    Error(Nil) -> None
  }

  let event = case public_games(db: context.db, team_filter:) {
    Ok(games) -> to_client.GamesLoaded(games:)
    Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
  }

  #(backend_model, effect.send_to_client(event))
}

fn public_games(
  db db: sqlight.Connection,
  team_filter team_filter: option.Option(String),
) -> Result(List(game.PublicGameSummary), db.QueryError) {
  let team_filter = case team_filter {
    Some(team_code) -> team_code
    None -> ""
  }

  case games_sql.list_public(db:, team_filter:) {
    Ok(rows) -> Ok(list.map(rows, game_summary_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

pub fn game_summary_from_row(
  row: games_sql.ListPublicRow,
) -> game.PublicGameSummary {
  game.PublicGameSummary(
    id: row.id,
    home: game.Team(
      code: row.home_code,
      name: row.home_name,
      slug: row.home_slug,
    ),
    away: game.Team(
      code: row.away_code,
      name: row.away_name,
      slug: row.away_slug,
    ),
    home_score: row.home_score,
    away_score: row.away_score,
    status: domain.game_status(row.final, row.period),
  )
}

pub fn load_games_for_ssr(
  server_context: ServerContext,
  team_filter: option.Option(String),
) -> Result(List(game.PublicGameSummary), db.QueryError) {
  let team_filter = case team_filter {
    Some(code) -> code
    None -> ""
  }
  case games_sql.list_public(db: server_context.db, team_filter:) {
    Ok(rows) -> Ok(list.map(rows, game_summary_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}
