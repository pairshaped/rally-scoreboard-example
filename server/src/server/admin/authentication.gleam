//// Demo authentication for the admin Mount.
////
//// This intentionally exercises Rally's generated authentication helpers in
//// the golden-path app. Password sign-in accepts admin@example.com/admin.
//// Sign-in code authentication shows a fixed demo code on the page,
//// pretending it was emailed.

import generated/rally/authentication as authentication_runtime
import gleam/list
import gleam/string

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
  normalize_email(email) == admin_email
  && authentication_runtime.verify(stored: password_hash(), secret: password)
}

pub fn verify_sign_in_code(email email: String, code code: String) -> Bool {
  normalize_email(email) == admin_email
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
    value: session_id,
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
      |> fn(cookie) { cookie == Ok(session_id) }
    Error(Nil) -> False
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

fn normalize_email(value: String) -> String {
  value
  |> string.trim
  |> string.lowercase
}
