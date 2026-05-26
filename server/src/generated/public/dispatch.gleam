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

import generated/public/request_context.{type RequestContext}
import lustre/effect.{type Effect}
import server/public/model.{type Model}
import server/public/pages/games as server_public_pages_games
import server/public/pages/games/id_ as server_public_pages_games_id_
import server/public/pages/standings as server_public_pages_standings
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
    to_server.LoadGames ->
      server_public_pages_games.load_games(
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.LoadGame(game_id:) ->
      server_public_pages_games_id_.load_game(
        game_id:,
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.LoadStandings ->
      server_public_pages_standings.load_standings(
        request_context:,
        server_context:,
        backend_model:,
      )
    to_server.LoadAdminGames -> #(backend_model, effect.none())
    to_server.CreateGame(home_code: _, away_code: _) -> #(
      backend_model,
      effect.none(),
    )
    to_server.UpdateScore(game_id: _, home_score: _, away_score: _, period: _) -> #(
      backend_model,
      effect.none(),
    )
    to_server.MarkFinal(game_id: _) -> #(backend_model, effect.none())
    to_server.CorrectResult(game_id: _, home_score: _, away_score: _) -> #(
      backend_model,
      effect.none(),
    )
  }
}
