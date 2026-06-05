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
import gleam/http
@target(erlang)
import gleam/http/request.{type Request, Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/io
@target(erlang)
import gleam/result
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import rally/runtime/http_server
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
pub type AppContext {
  AppContext(db: sqlight.Connection, session: app_session.Session)
}

@target(erlang)
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let assert Ok(key) = session_key()
  let session = app_session.new(key)
  let port = app_config.http_port(default: 8080)
  let context = AppContext(db:, session:)

  http_server.listen(
    port:,
    context:,
    config: http_server.default_config(),
    handlers: http_server.Handlers(
      auth: handle_auth_path,
      websocket: handle_websocket_path,
      admin: handle_admin_path,
      public: handle_public_path,
    ),
  )
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
  context context: AppContext,
) -> Response(ResponseData) {
  case
    app_auth_http.check_admin_session(
      req: req,
      db: context.db,
      session: context.session,
    )
  {
    Ok(_) ->
      app_document.response(
        req: req,
        path: req.path,
        db: context.db,
        session: context.session,
      )
    Error(Nil) -> app_auth_http.sign_in_redirect(req.path)
  }
}

@target(erlang)
fn handle_auth_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Result(Response(ResponseData), Nil) {
  let Request(path: path, method: method, ..) = req
  case method, path {
    http.Post, "/sign_in" ->
      app_auth_http.handle_sign_in_post(
        req: req,
        db: context.db,
        session: context.session,
      )
      |> Ok
    http.Get, "/sign_out" -> app_auth_http.handle_sign_out(req) |> Ok
    http.Post, "/sign_out" -> app_auth_http.handle_sign_out(req) |> Ok
    _, _ -> Error(Nil)
  }
}

@target(erlang)
fn handle_websocket_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Response(ResponseData) {
  let admin_authorized =
    app_auth_http.check_admin_session(
      req: req,
      db: context.db,
      session: context.session,
    )
    |> result.is_ok
  mist.websocket(
    req,
    app_ws.handler,
    fn(conn) { app_ws.on_init(conn, context.db, admin_authorized) },
    app_ws.on_close,
  )
}

@target(erlang)
fn handle_public_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Response(ResponseData) {
  app_document.response(
    req: req,
    path: req.path,
    db: context.db,
    session: context.session,
  )
}

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}
