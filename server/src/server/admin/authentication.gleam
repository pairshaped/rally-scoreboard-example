//// Demo authentication backed by the users table.
////
//// Password sign-in accepts admin@example.com/admin and fan@example.com/fan
//// after they have been seeded into the users table. Sign-in code
//// authentication uses a fixed demo code per user.
////
//// The auth cookie value is a signed token: `session_id.hmac_signature`. The
//// client cannot forge a valid token without the server secret, so checking
//// that the cookie is merely equal to the session ID is not enough.
////
//// Normalize email at every boundary before lookup. Store only normalized
//// email. Treat DB-loaded email as canonical.

import generated/runtime/authentication as authentication_runtime
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared/authentication_context
import sqlight

const demo_sign_in_code = "A1Z9Q"

const secret_key = "scoreboard-demo-secret"

const cookie_name = "scoreboard_admin"

const cookie_max_age = 3600

// --- DB-backed verification ---

pub fn verify_password(
  db db: sqlight.Connection,
  email email: String,
  password password: String,
) -> Option(Int) {
  let normalized = authentication_context.normalize_email(email)
  case
    sqlight.query(
      "SELECT id, password_hash FROM users WHERE email = ?1",
      on: db,
      with: [sqlight.text(normalized)],
      expecting: {
        use id <- decode.field(0, decode.int)
        use hash <- decode.field(1, decode.string)
        decode.success(#(id, hash))
      },
    )
  {
    Ok([#(user_id, stored_hash), ..]) ->
      case
        authentication_runtime.verify(stored: stored_hash, secret: password)
      {
        True -> Some(user_id)
        False -> None
      }
    _ -> None
  }
}

pub fn verify_sign_in_code(
  db db: sqlight.Connection,
  email email: String,
  code code: String,
) -> Option(Int) {
  let normalized = authentication_context.normalize_email(email)
  case
    sqlight.query(
      "SELECT id, email, sign_in_code_hash FROM users WHERE email = ?1",
      on: db,
      with: [sqlight.text(normalized)],
      expecting: {
        use id <- decode.field(0, decode.int)
        use scope <- decode.field(1, decode.string)
        use hash <- decode.field(2, decode.string)
        decode.success(#(id, scope, hash))
      },
    )
  {
    Ok([#(user_id, scope, stored_hash), ..]) ->
      case
        authentication_runtime.verify_sign_in_code(
          stored: stored_hash,
          scope:,
          code:,
          secret_key:,
        )
      {
        True -> Some(user_id)
        False -> None
      }
    _ -> None
  }
}

// --- Form pre-fill helpers (return demo values for the sign-in form) ---

pub fn email() -> String {
  "admin@example.com"
}

pub fn password() -> String {
  "admin"
}

pub fn sign_in_code() -> String {
  demo_sign_in_code
}

// --- Cookie helpers ---

pub fn issue_cookie(
  session_id session_id: String,
  user_id user_id: Int,
) -> authentication_runtime.Cookie {
  authentication_runtime.SetCookie(
    name: cookie_name,
    value: sign_token(session_id, user_id),
    max_age: cookie_max_age,
  )
}

pub fn clear_cookie() -> authentication_runtime.Cookie {
  authentication_runtime.ClearCookie(name: cookie_name)
}

pub fn is_authenticated(
  cookie_header cookie_header: Result(String, Nil),
  session_id session_id: String,
) -> Bool {
  case cookie_header {
    Ok(cookie_header) ->
      cookie_header
      |> parse_cookie_header
      |> list.key_find(cookie_name)
      |> fn(cookie) {
        case cookie {
          Ok(token) -> verify_signed_token(token, session_id)
          Error(Nil) -> False
        }
      }
    Error(Nil) -> False
  }
}

pub fn authenticated_user_id(
  cookie_header cookie_header: Result(String, Nil),
  session_id session_id: String,
) -> Option(Int) {
  case cookie_header {
    Ok(cookie_header) ->
      cookie_header
      |> parse_cookie_header
      |> list.key_find(cookie_name)
      |> fn(cookie) {
        case cookie {
          Ok(token) -> extract_user_id(token, session_id)
          Error(Nil) -> None
        }
      }
    Error(Nil) -> None
  }
}

// --- Token helpers ---

fn sign_token(session_id: String, user_id: Int) -> String {
  let payload = session_id <> "." <> int.to_string(user_id)
  let sig =
    crypto.hmac(<<payload:utf8>>, crypto.Sha256, <<secret_key:utf8>>)
    |> bit_array.base64_url_encode(False)
  payload <> "." <> sig
}

fn verify_signed_token(token: String, session_id: String) -> Bool {
  case parse_signed_token(token) {
    Ok(#(claimed_session, _user_id)) -> claimed_session == session_id
    Error(Nil) -> False
  }
}

fn extract_user_id(token: String, session_id: String) -> Option(Int) {
  case parse_signed_token(token) {
    Ok(#(claimed_session, user_id)) if claimed_session == session_id ->
      Some(user_id)
    _ -> None
  }
}

// nolint: deep_nesting -- crypto verification is naturally nested; extracting helpers would obscure the constant-time comparison control flow.
fn parse_signed_token(token: String) -> Result(#(String, Int), Nil) {
  case string.split_once(token, ".") {
    Ok(#(claimed_session, rest)) ->
      case string.split_once(rest, ".") {
        Ok(#(raw_user_id, provided_sig)) -> {
          let payload = claimed_session <> "." <> raw_user_id
          let expected_sig =
            crypto.hmac(<<payload:utf8>>, crypto.Sha256, <<secret_key:utf8>>)
            |> bit_array.base64_url_encode(False)
          case
            crypto.secure_compare(<<expected_sig:utf8>>, <<provided_sig:utf8>>)
          {
            True ->
              case int.parse(raw_user_id) {
                Ok(user_id) -> Ok(#(claimed_session, user_id))
                Error(Nil) -> Error(Nil)
              }
            False -> Error(Nil)
          }
        }
        Error(Nil) -> Error(Nil)
      }
    Error(Nil) -> Error(Nil)
  }
}

fn parse_cookie_header(header: String) -> List(#(String, String)) {
  header
  |> string.split(";")
  |> list.filter_map(fn(pair) {
    case string.split_once(string.trim(pair), "=") {
      Ok(#(name, value)) -> Ok(#(string.trim(name), string.trim(value)))
      Error(Nil) -> Error(Nil)
    }
  })
}
