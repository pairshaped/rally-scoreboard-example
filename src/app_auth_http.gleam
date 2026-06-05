@target(erlang)
import app_auth
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response
@target(erlang)
import gleam/result
@target(erlang)
import mist.{type Connection, type ResponseData}
@target(erlang)
import rally/runtime/auth_http
@target(erlang)
import rally/runtime/session
@target(erlang)
import sqlight

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
/// HTTP handler for POST /sign_in.
/// scoreboard_unified routes auth requests here before normal document routing.
pub fn handle_sign_in_post(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> response.Response(ResponseData) {
  case auth_http.read_sign_in_form(req, invalid_return_to: "/admin/games") {
    Ok(pairs) -> verify_credentials(db: db, session: session, pairs: pairs)
    Error(response) -> response
  }
}

@target(erlang)
/// HTTP handler for sign-out routes.
/// scoreboard_unified routes GET/POST /sign_out here so the session cookie can
/// be expired before redirecting.
pub fn handle_sign_out(
  req: Request(Connection),
) -> response.Response(ResponseData) {
  auth_http.sign_out(req, default_return_to: "/games", secure: False)
}

@target(erlang)
/// Redirect helper used by admin route protection.
/// scoreboard_unified calls this when an unauthenticated request targets /admin.
pub fn sign_in_redirect(return_to: String) -> response.Response(ResponseData) {
  auth_http.sign_in_redirect(return_to)
}

@target(erlang)
/// Admin session guard.
/// scoreboard_unified uses this for admin HTTP and websocket entrypoints, and
/// app_ssr uses it when deciding shell identity.
pub fn check_admin_session(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> Result(app_auth.AuthenticatedUser, Nil) {
  use user <- result.try(authenticated_user(req: req, db: db, session: session))
  case app_auth.can_access_admin(user) {
    True -> Ok(user)
    False -> Error(Nil)
  }
}

@target(erlang)
/// Request identity loader.
/// app_ssr and check_admin_session use this to turn cookies into an
/// AuthenticatedUser.
pub fn authenticated_user(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> Result(app_auth.AuthenticatedUser, Nil) {
  let cookies = request.get_cookies(req)
  use cookie_value <- result.try(session.find_auth_cookie(cookies))
  use user_id <- result.try(session.decode_user_id(
    encoded: cookie_value,
    session: session,
  ))
  app_auth.user_by_id(db: db, user_id: user_id)
}

@target(erlang)
fn verify_credentials(
  db db: sqlight.Connection,
  session session: session.AuthSession,
  pairs pairs: List(#(String, String)),
) -> response.Response(ResponseData) {
  let return_to =
    auth_http.form_value(pairs, "return_to")
    |> safe_admin_return_to

  case auth_http.form_value(pairs, "code") {
    Ok(code) ->
      case app_auth.verify_sign_in_code(db: db, code: code) {
        Ok(user_id) ->
          auth_http.issue_user_session(
            session: session,
            return_to: return_to,
            user_id: user_id,
            secure: False,
          )
        Error(Nil) -> auth_http.invalid_sign_in_redirect(return_to)
      }
    Error(Nil) -> auth_http.invalid_sign_in_redirect(return_to)
  }
}

@target(erlang)
fn safe_admin_return_to(path: Result(String, Nil)) -> String {
  case path {
    Ok("/admin") -> "/admin"
    Ok("/admin/" <> rest) -> "/admin/" <> rest
    _ -> "/admin/games"
  }
}
