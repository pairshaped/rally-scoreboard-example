//// Generated. Do not edit.
////
//// Root API ToServer dispatch for the admin Mount.
////
//// Derived from shared/api/to_server.gleam and the page/server modules
//// that define matching handlers. The WebSocket runtime decodes one typed
//// ToServer value, then calls this function so the backend can update its
//// model and emit zero or more ToClient messages.
////
//// Each ToServer constructor maps to an explicit snake_case server handler
//// (LoadAdminGames -> load_admin_games, UpdateScore -> update_score, etc.).
//// The shared page module's init_requests() declares which constructors
//// are needed for first render; generated SSR executes those requests
//// locally and generated client init sends them over WebSocket when
//// hydration is absent.
////
//// Page-data handlers return ToClient directly. Command handlers return
//// #(Model, Effect(ToClient)). Handlers receive constructor fields as
//// labeled args, plus request_context, server_context, and backend_model.
////
//// Constructors owned by the other Mount (public) are rejected through
//// the generated rejection helper, which logs the rejection as an issue
//// so operators can detect misrouted commands.

import generated/admin/request_context.{type RequestContext, RequestContext}
import generated/routes/admin as route
import generated/runtime/effect as server_effect
import generated/runtime/reject
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
    to_server.LoadGames ->
      reject.reject_invalid_command(
        mount: "admin",
        command: "LoadGames",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.LoadGame(game_id: _) ->
      reject.reject_invalid_command(
        mount: "admin",
        command: "LoadGame",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.LoadStandings ->
      reject.reject_invalid_command(
        mount: "admin",
        command: "LoadStandings",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.LoadTeam(slug: _) ->
      reject.reject_invalid_command(
        mount: "admin",
        command: "LoadTeam",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.LoadAdminGames -> {
      let request_context =
        RequestContext(..request_context, route: route.AdminGames)
      let result =
        server_admin_pages_games.load_admin_games(
          request_context:,
          server_context:,
        )
      #(backend_model, server_effect.send_to_client(result))
    }
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
