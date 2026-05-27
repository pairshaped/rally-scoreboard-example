//// Generated. Do not edit.
////
//// Server-side rendered HTML handler for the public Mount.
//// Derived from server/public/pages load/view functions, generated/public/router.gleam,
//// generated/runtime/env.gleam, and server/server_context.gleam.

import generated/public/router
import generated/runtime/env
import gleam/bit_array
import gleam/bytes_tree
import gleam/dict
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import libero/wire as libero_wire
import lustre/element
import mist.{type ResponseData}
import server/public/pages/games as public_games_handler
import server/public/pages/games/id_ as public_game_handler
import server/public/pages/standings as public_standings_handler
import server/public/pages/teams/slug_ as public_team_handler
import server/server_context.{type ServerContext}
import shared/api/to_client
import shared/public/pages/game_detail as public_game_detail_page
import shared/public/pages/games as public_games_page
import shared/public/pages/standings as public_standings_page
import shared/public/pages/team as public_team_page
import simplifile

@external(erlang, "server_generated_protocol_atoms_ffi", "ensure")
fn ensure_atoms() -> Nil

const shell_path = "src/server/public/shell.html"

pub fn handle_request(
  route route: router.Route,
  server_context server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  query query: dict.Dict(String, String),
) -> response.Response(ResponseData) {
  ensure_atoms()
  serve_html_shell(route, server_context, session_id, hostname, query)
}

fn serve_html_shell(
  route: router.Route,
  server_context: ServerContext,
  session_id: String,
  hostname: String,
  query: dict.Dict(String, String),
) -> response.Response(ResponseData) {
  let #(page_html, shared_state) = load_route_data(route, server_context, query)
  let html = case simplifile.read(shell_path) {
    Ok(content) ->
      inject_shell_content(
        content,
        route,
        session_id,
        hostname,
        query,
        page_html,
        shared_state,
      )
      |> append_string(browser_env_script())
    Error(_) ->
      inject_shell_content(
        fallback_shell(),
        route,
        session_id,
        hostname,
        query,
        page_html,
        shared_state,
      )
  }
  response.new(200)
  |> response.set_header("content-type", "text/html")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(html)))
}

fn inject_shell_content(
  shell: String,
  route: router.Route,
  session_id: String,
  hostname: String,
  query: dict.Dict(String, String),
  page_html: String,
  shared_state: String,
) -> String {
  let flags_base64 = build_flags_base64(route, session_id, hostname, query)
  let scripts =
    "<script>window.__RUNTIME_FLAGS__='"
    <> flags_base64
    <> "'</script>\n<script>window.__RUNTIME_CLIENT_SHARED_STATE__='"
    <> shared_state
    <> "'</script>\n"
  shell
  |> string.replace(each: "</head>", with: scripts <> "</head>")
  |> inject_page_html(page_html)
}

fn inject_page_html(shell: String, page_html: String) -> String {
  case page_html {
    "" -> shell
    _ ->
      string.replace(
        shell,
        each: "<div id=\"app\"></div>",
        with: "<div id=\"app\">" <> page_html <> "</div>",
      )
  }
}

fn load_route_data(
  route: router.Route,
  server_context: ServerContext,
  query: dict.Dict(String, String),
) -> #(String, String) {
  let nil_on_navigate = fn(_) { Nil }
  let nil_on_game = fn(_) { Nil }

  case route {
    router.Games -> {
      let team_filter = case dict.get(query, "team") {
        Ok(team) -> option.Some(team)
        Error(Nil) -> option.None
      }
      case
        public_games_handler.load_games_for_ssr(server_context, team_filter)
      {
        Ok(games) -> #(
          public_games_page.view_games_page(games, nil_on_navigate, nil_on_game)
            |> element.to_string,
          libero_wire.encode_flags(to_client.GamesLoaded(games:)),
        )
        Error(_) -> #("", "")
      }
    }
    router.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          case public_game_handler.load_game_for_ssr(server_context, game_id) {
            Ok(game) -> #(
              public_game_detail_page.view_game_detail_page(
                option.Some(game),
                nil_on_navigate,
              )
                |> element.to_string,
              libero_wire.encode_flags(to_client.GameLoaded(game:)),
            )
            Error(_) -> #("", "")
          }
        Error(_) -> #("", "")
      }
    router.Standings ->
      case public_standings_handler.load_standings_for_ssr(server_context) {
        Ok(rows) -> #(
          public_standings_page.view_standings_page(rows, nil_on_navigate)
            |> element.to_string,
          libero_wire.encode_flags(to_client.StandingsLoaded(rows:)),
        )
        Error(_) -> #("", "")
      }
    router.Team(slug) ->
      case public_team_handler.load_team_for_ssr(server_context, slug) {
        Ok(detail) -> #(
          public_team_page.view_team_page(
            option.Some(public_team_page.Model(team: detail)),
            nil_on_navigate,
            nil_on_game,
          )
            |> element.to_string,
          libero_wire.encode_flags(to_client.TeamLoaded(team: detail)),
        )
        Error(_) -> #("", "")
      }
    router.NotFound(_) -> #("", "")
  }
}

fn build_flags_base64(
  route: router.Route,
  session_id: String,
  hostname: String,
  query: dict.Dict(String, String),
) -> String {
  let #(name, params_json) = route_info(route)
  let json =
    "{\"route\":\""
    <> name
    <> "\",\"params\":"
    <> params_json
    <> ",\"session_id\":\""
    <> json_escape(session_id)
    <> "\",\"hostname\":\""
    <> json_escape(hostname)
    <> "\",\"query\":"
    <> query_json(query)
    <> "}"
  json
  |> bit_array.from_string
  |> bit_array.base64_encode(True)
}

fn query_json(query: dict.Dict(String, String)) -> String {
  let pairs =
    dict.fold(query, [], fn(acc, k, v) {
      [#("\"" <> json_escape(k) <> "\"", "\"" <> json_escape(v) <> "\""), ..acc]
    })
  "{"
  <> string.join(
    list.map(pairs, fn(pair) {
      let #(k, v) = pair
      k <> ":" <> v
    }),
    ",",
  )
  <> "}"
}

fn route_info(route: router.Route) -> #(String, String) {
  case route {
    router.Games -> #("Games", "null")
    router.GamesId(id) -> #("GamesId", "\"" <> json_escape(id) <> "\"")
    router.Standings -> #("Standings", "null")
    router.Team(slug) -> #("Team", "\"" <> json_escape(slug) <> "\"")
    router.NotFound(_) -> #("NotFound", "null")
  }
}

fn json_escape(value: String) -> String {
  value
  |> string.replace(each: "\\", with: "\\\\")
  |> string.replace(each: "\"", with: "\\\"")
  |> string.replace(each: "\n", with: "\\n")
  |> string.replace(each: "\r", with: "\\r")
  |> string.replace(each: "\t", with: "\\t")
}

fn browser_env_script() -> String {
  "<script>window.__APP_ENV__='" <> env.app_env_name() <> "'</script>"
}

fn fallback_shell() -> String {
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n  <meta charset=\"utf-8\">\n  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n</head>\n<body>\n  <div id=\"app\"></div>\n  <script type=\"module\" data-runtime-client>\n    import { main } from \"/_build/client/scoreboard_public_client.mjs\";\n    main();\n  </script>\n</body>\n</html>\n"
}

fn append_string(to: String, suffix: String) -> String {
  to <> suffix
}
