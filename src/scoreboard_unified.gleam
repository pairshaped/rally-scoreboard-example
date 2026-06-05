@target(erlang)
import app_auth
@target(erlang)
import app_auth_http
@target(erlang)
import app_config
@target(erlang)
import app_document
@target(erlang)
import app_ws
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response.{type Response}
@target(erlang)
import gleam/io
@target(erlang)
import gleam/option.{None, Some}
@target(erlang)
import gleam/string
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import rally/runtime/auth_http
@target(erlang)
import rally/runtime/http_server
@target(erlang)
import rally/runtime/session
@target(erlang)
import rally/runtime/static
@target(erlang)
import sqlight

@target(erlang)
const db_path = "db/scoreboard.db"

@target(erlang)
/// HTTP server context shared by route handlers.
/// rally/runtime/http_server passes this to auth, websocket, admin, and public
/// handlers on every request.
pub type AppContext {
  AppContext(db: sqlight.Connection, session: session.AuthSession)
}

@target(erlang)
/// Server entrypoint.
/// The Erlang release starts here, then this wires app handlers into
/// rally/runtime/http_server.
pub fn main() -> Nil {
  let assert Ok(db) = sqlight.open(db_path)
  let assert Ok(session) = auth_session()
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
fn auth_session() -> Result(session.AuthSession, session.AuthSessionConfigError) {
  case
    session.auth_session_from_env(
      env_var: "SCOREBOARD_SECRET_KEY_BASE",
      allow_missing_development_key: True,
    )
  {
    Ok(auth_session) -> Ok(auth_session)
    Error(error) -> {
      io.println_error(session.auth_session_config_error_message(error))
      Error(error)
    }
  }
}

@target(erlang)
fn handle_admin_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Response(ResponseData) {
  auth_http.protect(
    req: req,
    auth: app_auth_http.request_auth(db: context.db, session: context.session),
    render: fn(_user) {
      app_document.response(
        req: req,
        path: req.path,
        db: context.db,
        session: context.session,
      )
    },
  )
}

@target(erlang)
fn handle_auth_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Result(Response(ResponseData), Nil) {
  auth_http.route_standard(
    req: req,
    context: context,
    routes: auth_http.StandardAuthRoutes(
      sign_in_post: fn(req, context: AppContext) {
        auth_http.sign_in_with_code(
          req: req,
          session: context.session,
          verify_code: fn(code) {
            app_auth.verify_sign_in_code(db: context.db, code: code)
          },
          default_return_to: "/admin/games",
          return_to: app_auth_http.admin_return_to,
          secure: False,
        )
      },
      sign_out: fn(req, _context) {
        auth_http.sign_out(req, default_return_to: "/games", secure: False)
      },
    ),
  )
}

@target(erlang)
fn handle_websocket_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Response(ResponseData) {
  let admin_user = case
    auth_http.authorized_user(
      req: req,
      auth: app_auth_http.request_auth(db: context.db, session: context.session),
    )
  {
    Ok(user) -> Some(user)
    Error(Nil) -> None
  }
  mist.websocket(
    req,
    app_ws.handler,
    fn(conn) { app_ws.on_init(conn, context.db, admin_user) },
    app_ws.on_close,
  )
}

@target(erlang)
fn handle_public_path(
  req req: Request(Connection),
  context context: AppContext,
) -> Response(ResponseData) {
  case string.starts_with(req.path, "/assets/") {
    True ->
      static.serve_asset(
        root: "priv/static",
        path: string.drop_start(req.path, 8),
      )
    False ->
      app_document.response(
        req: req,
        path: req.path,
        db: context.db,
        session: context.session,
      )
  }
}

@target(javascript)
/// JavaScript-side compile anchor for the server module.
/// Browser builds can import this module without pulling in Erlang-only code.
pub fn ensure() -> Nil {
  Nil
}
