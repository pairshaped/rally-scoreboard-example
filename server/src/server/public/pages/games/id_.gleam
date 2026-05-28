//// Public server handlers for one game route.
////
//// The generated dispatch calls `load_game` — the snake_case form of the
//// LoadGame ToServer constructor. The handler receives constructor fields
//// as labeled args so it does not need to parse request_context.route.

import generated/public/request_context.{type RequestContext}
import generated/sql/server/games_sql
import server/helpers/db
import server/helpers/domain
import server/server_context.{type ServerContext}
import shared/api/domain/game
import shared/api/to_client.{type ToClient}
import sqlight

pub fn load_game(
  game_id game_id: Int,
  request_context _request_context: RequestContext,
  server_context context: ServerContext,
) -> ToClient {
  case public_game(db: context.db, game_id:) {
    Ok(game) -> to_client.GameLoaded(game:)
    Error(reason) -> to_client.GamesLoadFailed(reason: db.to_string(reason))
  }
}

fn public_game(
  db db: sqlight.Connection,
  game_id game_id: Int,
) -> Result(game.GameDetail, db.QueryError) {
  case games_sql.get_game(db:, game_id:) {
    Ok([row]) -> Ok(game_detail_from_row(row))
    Ok([]) -> Error(db.not_found(message: "game not found"))
    Ok(_) -> Error(db.unexpected_rows(message: "expected one game"))
    Error(err) -> Error(db.from_sqlight(err))
  }
}

fn game_detail_from_row(row: games_sql.GetGameRow) -> game.GameDetail {
  game.GameDetail(
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
    scoring_summary: [
      row.home_code <> " opened the scoring",
      row.away_code <> " answered late",
    ],
  )
}
