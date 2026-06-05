@target(erlang)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import rally/runtime/auth as runtime_auth
@target(erlang)
import sqlight.{type Connection}

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
const sign_in_code_secret = "scoreboard-demo-secret"

@target(erlang)
/// Authenticated server-side user record.
/// Rally request auth helpers use this for access policy, and app_ssr projects
/// its context into AuthenticationContext for shell rendering and hydration.
pub type AuthenticatedUser {
  AuthenticatedUser(context: AuthenticationContext, role: String)
}

@target(erlang)
/// Verifies the demo sign-in code and returns the admin user id.
/// The sign-in route calls this while processing POST /sign_in.
pub fn verify_sign_in_code(
  db db: Connection,
  code code: String,
) -> Result(Int, Nil) {
  case
    sqlight.query(
      "SELECT id, email, sign_in_code_hash FROM users WHERE role = 'admin' LIMIT 1",
      on: db,
      with: [],
      expecting: {
        use id <- decode.field(0, decode.int)
        use email <- decode.field(1, decode.string)
        use hash <- decode.field(2, decode.string)
        decode.success(#(id, email, hash))
      },
    )
  {
    Ok([#(user_id, email, stored_hash)]) ->
      case
        runtime_auth.verify_login_code(
          stored: stored_hash,
          scope: email,
          code:,
          secret_key: sign_in_code_secret,
        )
      {
        True -> Ok(user_id)
        False -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

@target(erlang)
/// Loads the authenticated user record after a session cookie decodes.
/// Rally request auth callbacks use this to build request identity.
pub fn user_by_id(
  db db: Connection,
  user_id user_id: Int,
) -> Result(AuthenticatedUser, Nil) {
  case
    sqlight.query(
      "SELECT id, email, display_name, role FROM users WHERE id = ?1 LIMIT 1",
      on: db,
      with: [sqlight.int(user_id)],
      expecting: user_decoder(),
    )
  {
    Ok([user, ..]) -> Ok(user)
    _ -> Error(Nil)
  }
}

@target(erlang)
/// Admin authorization policy for authenticated users.
/// Rally RequestAuth uses this as the admin access predicate.
pub fn can_access_admin(user: AuthenticatedUser) -> Bool {
  user.role == "admin"
}

@target(erlang)
fn user_decoder() -> decode.Decoder(AuthenticatedUser) {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use display_name <- decode.field(2, decode.optional(decode.string))
  use role <- decode.field(3, decode.string)
  decode.success(AuthenticatedUser(
    context: AuthenticationContext(
      user_id: id,
      email:,
      display_name: normalize_display_name(display_name),
    ),
    role:,
  ))
}

@target(erlang)
fn normalize_display_name(name: Option(String)) -> Option(String) {
  case name {
    Some(value) -> authentication_context.normalize_display_name(value)
    None -> None
  }
}
