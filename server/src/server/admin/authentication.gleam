//// Demo authentication for the admin Mount.
////
//// This intentionally exercises the Generator Framework's generated authentication helpers in
//// the golden-path app. Password sign-in accepts admin@example.com/admin.
//// Sign-in code authentication shows a fixed demo code on the page,
//// pretending it was emailed.
////
//// The auth cookie value is a signed token: `session_id.hmac_signature`. The
//// client cannot forge a valid token without the server secret, so checking
//// that the cookie is merely equal to the session ID is not enough.

import generated/runtime/authentication as authentication_runtime
import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import shared/authentication_context

const admin_email = "admin@example.com"

const admin_password = "admin"

const demo_sign_in_code = "A1Z9Q"

const secret_key = "scoreboard-demo-secret"

const cookie_name = "scoreboard_admin"

const cookie_max_age = 3600

pub fn email() -> String {
  admin_email
}

pub fn password() -> String {
  admin_password
}

pub fn sign_in_code() -> String {
  demo_sign_in_code
}

pub fn password_hash() -> String {
  authentication_runtime.hash(secret: admin_password)
}

pub fn sign_in_code_hash() -> String {
  authentication_runtime.hash_sign_in_code(
    scope: admin_email,
    code: demo_sign_in_code,
    secret_key:,
  )
}

pub fn verify_password(email email: String, password password: String) -> Bool {
  authentication_context.normalize_email(email) == admin_email
  && authentication_runtime.verify(stored: password_hash(), secret: password)
}

pub fn verify_sign_in_code(email email: String, code code: String) -> Bool {
  authentication_context.normalize_email(email) == admin_email
  && authentication_runtime.verify_sign_in_code(
    stored: sign_in_code_hash(),
    scope: admin_email,
    code:,
    secret_key:,
  )
}

pub fn issue_cookie(
  session_id session_id: String,
) -> authentication_runtime.Cookie {
  authentication_runtime.SetCookie(
    name: cookie_name,
    value: sign_token(session_id, admin_user_id),
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

const admin_user_id = 1

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
