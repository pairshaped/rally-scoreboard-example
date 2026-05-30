//// Generated. Do not edit.
////
//// Root API ToServer dispatch for the public Mount.
////
//// Derived from shared/api/to_server.gleam and the page/server modules
//// that define matching handlers. The WebSocket runtime decodes one typed
//// ToServer value, then calls this function so the backend can update its
//// model and emit zero or more ToClient messages.
////
//// Each ToServer constructor maps to an explicit snake_case server handler
//// (LoadGames -> load_games, LoadGame -> load_game, etc.). The shared page
//// module's init_requests() declares which constructors are needed for
//// first render; generated SSR executes those requests locally and generated
//// client init sends them over WebSocket when hydration is absent.
////
//// Page-data handlers return ToClient directly. Command handlers return
//// #(Model, Effect(ToClient)). Handlers receive constructor fields as
//// labeled args, plus request_context, server_context, and backend_model.
////
//// Constructors owned by the other Mount (admin) are rejected through
//// the generated rejection helper, which logs the rejection as an issue
//// so operators can detect misrouted commands.

import generated/public/request_context.{type RequestContext, RequestContext}
import generated/public/route
import generated/runtime/effect as server_effect
import generated/runtime/reject
import gleam/int
import lustre/effect.{type Effect}
import server/public/model.{type Model}
import server/public/pages/games as server_public_pages_games
import server/public/pages/games/id_ as server_public_pages_games_id_
import server/public/pages/standings as server_public_pages_standings
import server/public/pages/teams/slug_ as server_public_pages_teams_slug_
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
    to_server.LoadGames -> {
      let request_context =
        RequestContext(..request_context, route: route.Games)
      let result =
        server_public_pages_games.load_games(request_context:, server_context:)
      #(backend_model, server_effect.send_to_client(result))
    }
    to_server.LoadGame(game_id:) -> {
      let request_context =
        RequestContext(
          ..request_context,
          route: route.GamesId(id: int.to_string(game_id)),
        )
      let result =
        server_public_pages_games_id_.load_game(
          game_id:,
          request_context:,
          server_context:,
        )
      #(backend_model, server_effect.send_to_client(result))
    }
    to_server.LoadStandings -> {
      let request_context =
        RequestContext(..request_context, route: route.Standings)
      let result =
        server_public_pages_standings.load_standings(
          request_context:,
          server_context:,
        )
      #(backend_model, server_effect.send_to_client(result))
    }
    to_server.LoadTeam(slug:) -> {
      let request_context =
        RequestContext(..request_context, route: route.Team(slug:))
      let result =
        server_public_pages_teams_slug_.load_team(
          slug:,
          request_context:,
          server_context:,
        )
      #(backend_model, server_effect.send_to_client(result))
    }
    to_server.LoadAdminGames ->
      reject.reject_invalid_command(
        mount: "public",
        command: "LoadAdminGames",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.UpdateScore(game_id: _, home_score: _, away_score: _, period: _) ->
      reject.reject_invalid_command(
        mount: "public",
        command: "UpdateScore",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.MarkFinal(game_id: _) ->
      reject.reject_invalid_command(
        mount: "public",
        command: "MarkFinal",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
    to_server.CorrectResult(game_id: _, home_score: _, away_score: _) ->
      reject.reject_invalid_command(
        mount: "public",
        command: "CorrectResult",
        session_id: request_context.session_id,
        user_id: request_context.user_id,
        hostname: request_context.hostname,
        server_context:,
        backend_model:,
      )
  }
}
