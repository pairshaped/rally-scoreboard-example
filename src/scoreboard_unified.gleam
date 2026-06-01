@target(erlang)
import gleam/bytes_tree
@target(erlang)
import gleam/erlang/process
@target(erlang)
import gleam/http/request.{type Request, Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/io
@target(erlang)
import gleam/option.{None}
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import server/ws
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let port = 8080

  let handler = fn(req: Request(Connection)) {
    let Request(path: path, ..) = req
    case path {
      "/ws" ->
        mist.websocket(
          req,
          ws.handler,
          fn(conn) { ws.on_init(conn, db) },
          ws.on_close,
        )
      _ ->
        case string.starts_with(path, "/_build/") {
          True -> serve_static(string.drop_start(path, 8))
          False -> html_response(app_html(path))
        }
    }
  }

  io.println("Listening on http://localhost:" <> int.to_string(port))
  let assert Ok(_) =
    mist.new(handler)
    |> mist.port(port)
    |> mist.start
  process.sleep_forever()
}

@target(erlang)
fn serve_static(path: String) -> Response(ResponseData) {
  let content_type = case string.ends_with(path, ".mjs") {
    True -> "application/javascript; charset=utf-8"
    False ->
      case string.ends_with(path, ".css") {
        True -> "text/css; charset=utf-8"
        False -> "application/octet-stream"
      }
  }

  case mist.send_file("build/dev/javascript/" <> path, offset: 0, limit: None) {
    Ok(data) ->
      response.new(200)
      |> response.set_header("content-type", content_type)
      |> response.set_body(data)
    Error(reason) -> {
      io.println(
        "Static file not found: "
        <> path
        <> " ("
        <> string.inspect(reason)
        <> ")",
      )
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
    }
  }
}

@target(erlang)
fn html_response(body: String) -> Response(ResponseData) {
  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

@target(erlang)
fn app_html(path: String) -> String {
  let entrypoint = case string.starts_with(path, "/admin") {
    True -> "admin_app.mjs"
    False -> "public_app.mjs"
  }

  "<!doctype html>
<html>
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>Scoreboard</title>
</head>
<body>
  <div id=\"app\"></div>
  <script type=\"module\">
    import { main } from '/_build/scoreboard_unified/" <> entrypoint <> "';
    main();
  </script>
</body>
</html>"
}
