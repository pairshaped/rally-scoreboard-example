//// Admin server handlers for game management.
////
//// These functions are named after ToServer constructors. Generated admin
//// dispatch calls them to mutate the database and emit ToClient messages.
//// After writing to the database, admin handlers also broadcast
//// GameScoreUpdated and StandingsUpdated through the live-update pubsub
//// so all connected public clients see changes without a page reload.
////
//// The generated dispatch calls `load_admin_games` — the snake_case form of
//// the LoadAdminGames ToServer constructor. Page-data handlers like this
//// return ToClient directly so the dispatch can wrap the result without
//// changing backend model.

import generated/admin/request_context.{type RequestContext}
import generated/runtime/effect.{type Effect}
import generated/runtime/live_updates
import generated/sql/server/games_sql
import generated/sql/server/standings_sql
import gleam/bool
import gleam/list
import server/admin/model.{type Model}
import server/helpers/db
import server/helpers/domain
import server/server_context.{type ServerContext}
import shared/api/domain/game as admin_game
import shared/api/domain/standing
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_admin_games(
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
) -> ToClient {
  case admin_games(context.db) {
    Ok(games) -> to_client.AdminGamesLoaded(games:)
    Error(reason) -> to_client.AdminError(reason: db.to_string(reason))
  }
}

pub fn create_game(
  home_code home_code: String,
  away_code away_code: String,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case create_admin_game(db: context.db, home_code:, away_code:) {
    Ok(game) -> to_client.GameCreated(game:)
    Error(reason) -> to_client.AdminError(reason: db.to_string(reason))
  }

  #(backend_model, effect.send_to_client(event))
}

pub fn update_score(
  game_id game_id: Int,
  home_score home_score: Int,
  away_score away_score: Int,
  period period: String,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case
    update_admin_score(
      db: context.db,
      game_id:,
      home_score:,
      away_score:,
      period:,
    )
  {
    Ok(game) -> {
      live_updates.broadcast(
        to_client.GameScoreUpdated(update: admin_game.GameScoreUpdate(
          game_id:,
          home_score:,
          away_score:,
          period:,
          status: game.status,
        )),
      )
      effect.send_to_client(to_client.ScoreUpdateSaved(game:))
    }
    Error(reason) ->
      effect.send_to_client(to_client.AdminError(reason: db.to_string(reason)))
  }

  #(backend_model, event)
}

pub fn mark_final(
  game_id game_id: Int,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case current_score(db: context.db, game_id:) {
    Ok(#(home_score, away_score)) ->
      case final_admin_result(db: context.db, game_id:) {
        Ok(game) -> {
          live_updates.broadcast(
            to_client.GameScoreUpdated(update: admin_game.GameScoreUpdate(
              game_id:,
              home_score:,
              away_score:,
              period: game.period,
              status: game.status,
            )),
          )
          broadcast_live_standings(context.db)
          effect.send_to_client(to_client.ResultSaved(game:))
        }
        Error(reason) ->
          effect.send_to_client(
            to_client.AdminError(reason: db.to_string(reason)),
          )
      }
    Error(reason) ->
      effect.send_to_client(to_client.AdminError(reason: db.to_string(reason)))
  }

  #(backend_model, event)
}

pub fn correct_result(
  game_id game_id: Int,
  home_score home_score: Int,
  away_score away_score: Int,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case
    update_admin_score(
      db: context.db,
      game_id:,
      home_score:,
      away_score:,
      period: "Final",
    )
  {
    Ok(_score_result) ->
      case final_admin_result(db: context.db, game_id:) {
        Ok(game) -> {
          live_updates.broadcast(
            to_client.GameScoreUpdated(update: admin_game.GameScoreUpdate(
              game_id:,
              home_score:,
              away_score:,
              period: game.period,
              status: game.status,
            )),
          )
          broadcast_live_standings(context.db)
          effect.send_to_client(to_client.ResultSaved(game:))
        }
        Error(reason) ->
          effect.send_to_client(
            to_client.AdminError(reason: db.to_string(reason)),
          )
      }
    Error(reason) ->
      effect.send_to_client(to_client.AdminError(reason: db.to_string(reason)))
  }

  #(backend_model, event)
}

fn broadcast_live_standings(db: sqlight.Connection) -> Nil {
  case live_standings(db) {
    Ok(rows) -> live_updates.broadcast(to_client.StandingsUpdated(rows:))
    Error(_) -> Nil
  }
}

fn live_standings(
  db: sqlight.Connection,
) -> Result(List(standing.StandingRow), db.QueryError) {
  case standings_sql.list_standings(db:) {
    Ok(rows) -> Ok(list.map(rows, domain.standing_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn admin_games(
  db: sqlight.Connection,
) -> Result(List(admin_game.AdminGameSummary), db.QueryError) {
  case games_sql.list_admin_games(db:) {
    Ok(rows) -> Ok(list.map(rows, admin_summary_from_row))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn create_admin_game(
  db db: sqlight.Connection,
  home_code home_code: String,
  away_code away_code: String,
) -> Result(admin_game.AdminGameDetail, db.QueryError) {
  use <- bool.guard(
    when: home_code == away_code,
    return: Error(db.validation(message: "home and away teams must differ")),
  )

  case games_sql.create_game(db:, home_code:, away_code:) {
    Ok([row]) -> Ok(admin_detail_from_create(row))
    Ok([]) -> Error(db.not_found(message: "game not created"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one created game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn update_admin_score(
  db db: sqlight.Connection,
  game_id game_id: Int,
  home_score home_score: Int,
  away_score away_score: Int,
  period period: String,
) -> Result(admin_game.AdminGameDetail, db.QueryError) {
  case
    games_sql.update_game_score(
      db:,
      home_score:,
      away_score:,
      period:,
      game_id:,
    )
  {
    Ok([row]) -> Ok(admin_detail_from_update_score(row))
    Ok([]) -> Error(db.not_found(message: "game not found"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one updated game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn current_score(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(#(Int, Int), db.QueryError) {
  case games_sql.get_game(db:, game_id:) {
    Ok([row]) -> Ok(#(row.home_score, row.away_score))
    Ok([]) -> Error(db.not_found(message: "game not found"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn final_admin_result(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(admin_game.AdminGameDetail, db.QueryError) {
  case games_sql.update_game_final(db:, game_id:) {
    Ok([row]) -> Ok(admin_detail_from_final(row))
    Ok([]) -> Error(db.not_found(message: "game not found"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one updated game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn admin_summary_from_row(
  row: games_sql.ListAdminGamesRow,
) -> admin_game.AdminGameSummary {
  admin_game.AdminGameSummary(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: domain.game_status(row.final, row.period),
    needs_attention: row.final == 0,
  )
}

fn admin_detail_from_create(
  row: games_sql.CreateGameRow,
) -> admin_game.AdminGameDetail {
  admin_game.AdminGameDetail(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: domain.game_status(row.final, row.period),
    period: row.period,
  )
}

fn admin_detail_from_update_score(
  row: games_sql.UpdateGameScoreRow,
) -> admin_game.AdminGameDetail {
  admin_game.AdminGameDetail(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: domain.game_status(row.final, row.period),
    period: row.period,
  )
}

fn admin_detail_from_final(
  row: games_sql.UpdateGameFinalRow,
) -> admin_game.AdminGameDetail {
  admin_game.AdminGameDetail(
    id: row.id,
    home_code: row.home_code,
    away_code: row.away_code,
    home_score: row.home_score,
    away_score: row.away_score,
    status: domain.game_status(row.final, row.period),
    period: row.period,
  )
}
