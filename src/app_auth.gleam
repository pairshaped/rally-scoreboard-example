@target(erlang)
import app_session
@target(erlang)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/crypto
@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, None, Some}
@target(erlang)
import gleam/string
@target(erlang)
import sqlight.{type Connection}

@target(erlang)
const sign_in_code_secret = "scoreboard-demo-secret"

@target(erlang)
pub type AuthenticatedUser {
  AuthenticatedUser(context: AuthenticationContext, role: String)
}

@target(erlang)
pub fn find_session(cookies: List(#(String, String))) -> Result(String, Nil) {
  list.find_map(cookies, fn(pair) {
    case pair.0 {
      name if name == app_session.session_cookie -> Ok(pair.1)
      _ -> Error(Nil)
    }
  })
}

@target(erlang)
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
      case verify_hash(stored_hash:, scope: email, code:) {
        True -> Ok(user_id)
        False -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

@target(erlang)
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

@target(erlang)
fn verify_hash(
  stored_hash stored_hash: String,
  scope scope: String,
  code code: String,
) -> Bool {
  case parse_hash(stored_hash) {
    Ok(expected) -> {
      let input = normalize(scope) <> ":" <> normalize(code)
      let actual =
        crypto.hmac(
          bit_array.from_string(input),
          crypto.Sha256,
          bit_array.from_string(sign_in_code_secret),
        )
      crypto.secure_compare(actual, expected)
    }
    Error(Nil) -> False
  }
}

@target(erlang)
fn normalize(value: String) -> String {
  value |> string.trim |> string.uppercase
}

@target(erlang)
fn parse_hash(stored: String) -> Result(BitArray, Nil) {
  case string.split(stored, "$") {
    ["", "runtime-sign-in-code-hmac-sha256", "v=1", hash] ->
      bit_array.base64_url_decode(hash)
    _ -> Error(Nil)
  }
}
