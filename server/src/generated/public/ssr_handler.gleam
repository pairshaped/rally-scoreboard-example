//// Generated. Do not edit.
////
//// Server-rendered HTML handler for the public Mount.
//// Derived from server/public/pages load/view functions, generated/public/route.gleam,
//// server/public/shell.html, and server/server_context.gleam.
////
//// Each SSR branch calls the same unified page `load` function that the
//// WebSocket dispatch uses, renders the shared page view from the returned
//// ToClient, and embeds the same ToClient value as base64 ETF for browser init.

import generated/public/request_context.{type RequestContext, RequestContext}
import generated/public/route.{type Route}
import generated/runtime/ssr
import gleam/dict
import gleam/http/response
import gleam/io
import gleam/option.{type Option}
import libero/wire as libero_wire
import lustre/element
import mist.{type ResponseData}
import server/public/client_shared_state_loader
import server/public/pages/games as public_games_handler
import server/public/pages/games/id_ as public_game_handler
import server/public/pages/standings as public_standings_handler
import server/public/pages/teams/slug_ as public_team_handler
import server/server_context.{type ServerContext}
import shared/api/to_client
import shared/authentication_context.{type AuthenticationContext}
import shared/public/pages/games/id_ as public_game_detail_page
import shared/public/pages/games as public_games_page
import shared/public/pages/standings as public_standings_page
import shared/public/pages/teams/slug_ as public_team_page

@external(erlang, "server_generated_protocol_atoms_ffi", "ensure")
fn ensure_atoms() -> Nil

const shell_path = "src/server/public/shell.html"

pub fn handle_request(
  route route: Route,
  server_context server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  query query: dict.Dict(String, String),
  authentication_context authentication_context: Option(AuthenticationContext),
) -> response.Response(ResponseData) {
  ensure_atoms()
  let context =
    client_shared_state_loader.load(
      db: server_context.db,
      route:,
      authentication_context:,
    )
  let client_shared_state_base64 = libero_wire.encode_flags(context)
  let request_context =
    RequestContext(
      route:,
      query:,
      session_id:,
      user_id: option.map(authentication_context, fn(ctx) { ctx.user_id }),
      hostname:,
    )
  let #(page_html, shared_state_base64) =
    load_route_data(request_context, server_context)
  ssr.render_shell_response(
    shell_path:,
    page_html:,
    shared_state_base64:,
    client_shared_state_base64:,
    fallback_shell: public_fallback_shell(),
  )
}

fn load_route_data(
  request_context: RequestContext,
  server_context: ServerContext,
) -> #(String, String) {
  let nil_on_navigate = fn(_) { Nil }
  let nil_on_game = fn(_) { Nil }

  case request_context.route {
    route.Games -> {
      let result = public_games_handler.load(request_context:, server_context:)
      case result {
        to_client.GamesLoaded(games:) -> #(
          public_games_page.view_games_page(games, nil_on_navigate, nil_on_game)
            |> element.to_string,
          libero_wire.encode_flags(result),
        )
        to_client.GamesLoadFailed(reason:) -> {
          let _ = io.println_error("SSR public/games load failed: " <> reason)
          #(
            public_games_page.view_games_page([], nil_on_navigate, nil_on_game)
              |> element.to_string,
            "",
          )
        }
        _ -> #("", "")
      }
    }
    route.GamesId(_) -> {
      let result = public_game_handler.load(request_context:, server_context:)
      case result {
        to_client.GameLoaded(game:) -> #(
          public_game_detail_page.view_game_detail_page(
            option.Some(game),
            nil_on_navigate,
          )
            |> element.to_string,
          libero_wire.encode_flags(result),
        )
        to_client.GamesLoadFailed(reason:) -> {
          let _ =
            io.println_error("SSR public/game-detail load failed: " <> reason)
          #(
            public_game_detail_page.view_game_detail_page(
              option.None,
              nil_on_navigate,
            )
              |> element.to_string,
            "",
          )
        }
        _ -> #("", "")
      }
    }
    route.Standings -> {
      let result =
        public_standings_handler.load(request_context:, server_context:)
      case result {
        to_client.StandingsLoaded(rows:) -> #(
          public_standings_page.view_standings_page(rows, nil_on_navigate)
            |> element.to_string,
          libero_wire.encode_flags(result),
        )
        to_client.GamesLoadFailed(reason:) -> {
          let _ =
            io.println_error("SSR public/standings load failed: " <> reason)
          #(
            public_standings_page.view_standings_page([], nil_on_navigate)
              |> element.to_string,
            "",
          )
        }
        _ -> #("", "")
      }
    }
    route.Team(_) -> {
      let result = public_team_handler.load(request_context:, server_context:)
      case result {
        to_client.TeamLoaded(team:) -> #(
          public_team_page.view_team_page(
            option.Some(public_team_page.Model(team:)),
            nil_on_navigate,
            nil_on_game,
          )
            |> element.to_string,
          libero_wire.encode_flags(result),
        )
        to_client.GamesLoadFailed(reason:) -> {
          let _ = io.println_error("SSR public/team load failed: " <> reason)
          #(
            public_team_page.view_team_page(
              option.None,
              nil_on_navigate,
              nil_on_game,
            )
              |> element.to_string,
            "",
          )
        }
        _ -> #("", "")
      }
    }
    route.SignIn | route.SignInPassword | route.SignInCode -> #("", "")
    route.NotFound -> #("", "")
  }
}

fn public_fallback_shell() -> String {
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n</head>\n<body>\n  <div id=\"app\"></div>\n  <script type=\"module\" data-runtime-client>\n    import { main } from \"/_build/client/scoreboard_public_client.mjs\";\n    main();\n  </script>\n</body>\n</html>\n"
}
