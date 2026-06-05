@target(erlang)
import app_auth
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/http/response
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
/// App-owned auth callbacks for Rally request auth.
/// Rally owns cookie/session extraction; Scoreboard owns user lookup and admin
/// authorization policy.
pub fn request_auth(
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> auth_http.RequestAuth(app_auth.AuthenticatedUser) {
  auth_http.RequestAuth(
    session: session,
    load_user: fn(user_id) { app_auth.user_by_id(db: db, user_id: user_id) },
    can_access: app_auth.can_access_admin,
  )
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
