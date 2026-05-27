//// Generated. Do not edit.
////
//// Server-rendered HTML handler for the admin Mount.
//// Derived from server/admin/pages load/view functions, generated/admin/route.gleam,
//// and server/server_context.gleam.

import generated/admin/route.{type Route}
import generated/runtime/ssr
import gleam/dict
import gleam/http/response
import gleam/io
import libero/wire as libero_wire
import lustre/element
import mist.{type ResponseData}
import server/admin/pages/games as admin_games_handler
import server/helpers/db
import server/server_context.{type ServerContext}
import shared/admin/pages/games as admin_games_page
import shared/api/to_client

@external(erlang, "server_generated_protocol_atoms_ffi", "ensure")
fn ensure_atoms() -> Nil

const shell_path = "src/server/admin/shell.html"

pub fn handle_request(
  route route: Route,
  server_context server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  query query: dict.Dict(String, String),
) -> response.Response(ResponseData) {
  let _ = session_id
  let _ = hostname
  let _ = query
  ensure_atoms()
  let #(page_html, shared_state_base64) = load_route_data(route, server_context)
  ssr.render_shell_response(
    shell_path:,
    page_html:,
    shared_state_base64:,
    fallback_shell: admin_fallback_shell(),
  )
}

fn load_route_data(
  route: Route,
  server_context: ServerContext,
) -> #(String, String) {
  case route {
    route.AdminGames ->
      case admin_games_handler.load_admin_games_for_ssr(server_context) {
        Ok(games) -> {
          let nil_on_adjust = fn(_, _, _, _) { Nil }
          let nil_on_final = fn(_) { Nil }
          #(
            admin_games_page.view_games(
              games,
              nil_on_adjust,
              nil_on_adjust,
              nil_on_final,
            )
              |> element.to_string,
            libero_wire.encode_flags(to_client.AdminGamesLoaded(games:)),
          )
        }
        Error(reason) -> {
          let _ =
            io.println_error(
              "SSR admin/games load failed: " <> db.to_string(reason),
            )
          #(
            admin_games_page.view_games(
              [],
              nil_on_adjust,
              nil_on_adjust,
              nil_on_final,
            )
              |> element.to_string,
            "",
          )
        }
      }
    _ -> #("", "")
  }
}

fn nil_on_adjust(_a, _b, _c, _d) -> Nil {
  Nil
}

fn nil_on_final(_a) -> Nil {
  Nil
}

fn admin_fallback_shell() -> String {
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n</head>\n<body>\n  <div id=\"app\"></div>\n  <script type=\"module\" data-runtime-client>\n    import { main } from \"/_build/client/scoreboard_admin_client.mjs\";\n    main();\n  </script>\n</body>\n</html>\n"
}
