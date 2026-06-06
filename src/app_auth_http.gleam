@target(erlang)
import app_auth
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
/// App-owned auth callbacks for Rally request auth.
/// Rally owns cookie/session extraction; Scoreboard owns user lookup and admin
/// authorization policy.
pub fn request_auth(
  db db: sqlight.Connection,
  session session: session.AuthSession,
) -> auth_http.RequestAuth(app_auth.AuthenticatedUser) {
  auth_http.RequestAuth(
    session:,
    load_user: fn(user_id) { app_auth.user_by_id(db:, user_id:) },
    can_access: app_auth.can_access_admin,
  )
}

@target(erlang)
/// Return-path policy for the admin sign-in flow.
/// Rally owns safe local URL handling; Scoreboard narrows successful sign-ins
/// to admin routes.
pub fn admin_return_to(path: String) -> String {
  case path {
    "/admin" -> "/admin"
    "/admin/" <> rest -> "/admin/" <> rest
    _ -> "/admin/games"
  }
}
