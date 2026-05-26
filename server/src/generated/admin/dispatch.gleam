//// Generated. Do not edit.
////
//// Root API ToServer dispatch.
////
//// Derived from shared/api/to_server.gleam and the page/server modules
//// that define matching `*_to_server` handlers. The WebSocket runtime
//// decodes one typed ToServer value, then calls this function so the
//// backend can update its model and emit zero or more ToClient messages.
//// If a constructor has no discovered handler yet, Rally keeps the
//// branch explicit and returns no effect.

import generated/admin/request_context.{type RequestContext}
import lustre/effect.{type Effect}
import server/admin/model.{type Model}
import server/admin/pages/games as server_admin_pages_games
import server/server_context.{type ServerContext}
import shared/api/to_client.{type ToClient}
import shared/api/to_server.{type ToServer}

pub fn to_server(
  msg msg: ToServer,
  request_context request_context: RequestContext,
  server_context server_context: ServerContext,
  backend_model backend_model: Model,
) -> #(Model, Effect(ToClient)) {
  case msg {
    to_server.LoadGames -> #(backend_model, effect.none())
    to_server.LoadGame(game_id: _) -> #(backend_model, effect.none())
    to_server.LoadStandings -> #(backend_model, effect.none())
    to_server.LoadAdminGames ->
      server_admin_pages_games.load_admin_games(
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.CreateGame(home_code:, away_code:) ->
      server_admin_pages_games.create_game(
        home_code:,
        away_code:,
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.UpdateScore(game_id:, home_score:, away_score:, period:) ->
      server_admin_pages_games.update_score(
        game_id:,
        home_score:,
        away_score:,
        period:,
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.MarkFinal(game_id:) ->
      server_admin_pages_games.mark_final(
        game_id:,
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.CorrectResult(game_id:, home_score:, away_score:) ->
      server_admin_pages_games.correct_result(
        game_id:,
        home_score:,
        away_score:,
        request_context:,
        server_context:,
        backend_model:,
      )
  }
}
