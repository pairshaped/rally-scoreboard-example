//// Public server handlers for one game route.
////
//// Generated public dispatch calls this module when the client asks for a
//// specific game by id.

import generated/public/request_context.{type RequestContext}
import generated/rally/effect.{type Effect}
import generated/sql/server/games_sql
import server/helpers/db
import server/public/model.{type Model}
import server/server_context.{type ServerContext}
import shared/api/domain/game
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_game(
  game_id game_id: Int,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  let event = case public_game(db: context.db, game_id:) {
    Ok(game) -> to_client.GameLoaded(game:)
    Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
  }

  #(backend_model, effect.send_to_client(event))
}

fn public_game(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(game.GameDetail, db.QueryError) {
  case games_sql.get(db:, game_id:) {
    Ok([row]) -> Ok(game_detail_from_row(row))
    Ok([]) -> Error(db.not_found(message: "game not found"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn game_detail_from_row(row: games_sql.GetRow) -> game.GameDetail {
  game.GameDetail(
    id: row.id,
    home: game.Team(code: row.home_code, name: row.home_name),
    away: game.Team(code: row.away_code, name: row.away_name),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.final, row.period),
    scoring_summary: [
      row.home_code <> " opened the scoring",
      row.away_code <> " answered late",
    ],
  )
}

fn game_status(final: Int, period: String) -> game.GameStatus {
  case final {
    1 -> game.Final
    _ -> game.Live(period)
  }
}
