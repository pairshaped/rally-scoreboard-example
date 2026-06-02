@target(erlang)
import app_assets
@target(erlang)
import app_auth_http
@target(erlang)
import app_config
@target(erlang)
import app_document
@target(erlang)
import app_session
@target(erlang)
import app_ws
@target(erlang)
import gleam/crypto
@target(erlang)
import gleam/erlang/process
@target(erlang)
import gleam/http
@target(erlang)
import gleam/http/request.{type Request, Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/io
@target(erlang)
import gleam/result
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let assert Ok(key) = session_key()
  let session = app_session.new(key)
  let port = app_config.http_port(default: 8080)

  let handler = fn(req: Request(Connection)) {
    let Request(path: path, method: method, ..) = req
    case method, path {
      http.Post, "/sign_in" ->
        app_auth_http.handle_sign_in_post(req: req, db: db, session: session)
      http.Get, "/sign_out" -> app_auth_http.handle_sign_out(req)
      http.Post, "/sign_out" -> app_auth_http.handle_sign_out(req)
      _, "/ws" -> {
        let admin_authorized =
          app_auth_http.check_admin_session(req: req, db: db, session: session)
          |> result.is_ok
        mist.websocket(
          req,
          app_ws.handler,
          fn(conn) { app_ws.on_init(conn, db, admin_authorized) },
          app_ws.on_close,
        )
      }
      _, _ ->
        case string.starts_with(path, "/_build/") {
          True -> app_assets.serve_static(string.drop_start(path, 8))
          False ->
            case string.starts_with(path, "/admin") {
              True -> handle_admin_path(req: req, db: db, session: session)
              False ->
                app_document.response(
                  req: req,
                  path: path,
                  db: db,
                  session: session,
                )
            }
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
fn session_key() -> Result(BitArray, app_config.SecretKeyError) {
  case app_config.secret_key() {
    Ok(key) -> Ok(key)
    Error(app_config.MissingSecret) -> {
      io.println_error(
        app_config.secret_key_error_message(app_config.MissingSecret)
        <> "; using an in-memory development key",
      )
      Ok(crypto.strong_random_bytes(32))
    }
    Error(error) -> {
      io.println_error(app_config.secret_key_error_message(error))
      Error(error)
    }
  }
}

@target(erlang)
fn handle_admin_path(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> Response(ResponseData) {
  case app_auth_http.check_admin_session(req: req, db: db, session: session) {
    Ok(_) ->
      app_document.response(req: req, path: req.path, db: db, session: session)
    Error(Nil) -> app_auth_http.sign_in_redirect(req.path)
  }
}
