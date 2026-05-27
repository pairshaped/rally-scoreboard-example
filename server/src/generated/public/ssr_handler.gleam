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
import gleam/list
import gleam/string
import mist.{type ResponseData}
import simplifile

@external(erlang, "server_generated_protocol_atoms_ffi", "ensure")
fn ensure_atoms() -> Nil

import server/server_context.{type ServerContext}

const shell_path = "src/server/public/shell.html"

pub fn handle_request(
  route route: router.Route,
  server_context _server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  query query: dict.Dict(String, String),
) -> response.Response(ResponseData) {
  ensure_atoms()
  serve_html_shell(route, session_id, hostname, query)
}

fn serve_html_shell(
  route: router.Route,
  session_id: String,
  hostname: String,
  query: dict.Dict(String, String),
) -> response.Response(ResponseData) {
  let html = case simplifile.read(shell_path) {
    Ok(content) ->
      inject_hydration(content, route, session_id, hostname, query)
      <> browser_env_script()
    Error(_) ->
      inject_hydration(fallback_shell(), route, session_id, hostname, query)
      <> browser_env_script()
  }
  response.new(200)
  |> response.set_header("content-type", "text/html")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(html)))
}

fn inject_hydration(
  shell: String,
  route: router.Route,
  session_id: String,
  hostname: String,
  query: dict.Dict(String, String),
) -> String {
  let flags_base64 = build_flags_base64(route, session_id, hostname, query)
  let scripts =
    "<script>window.__RUNTIME_FLAGS__='"
    <> flags_base64
    <> "'</script>\n<script>window.__RUNTIME_CLIENT_SHARED_STATE__='{}'</script>\n"
  string.replace(shell, each: "</head>", with: scripts <> "</head>")
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
