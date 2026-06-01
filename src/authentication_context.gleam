//// Shared authentication context for the signed-in browser identity.
////
//// Mounts consume this type. They do not own authentication.
//// Derived from the Generator Framework's authentication runtime contract.
//// See docs/adr/0008-use-authentication-context-for-shared-identity.md.

import gleam/option.{type Option, None, Some}
import gleam/string

pub type AuthenticationContext {
  AuthenticationContext(
    user_id: Int,
    email: String,
    display_name: Option(String),
  )
}

pub fn display_label(context: AuthenticationContext) -> String {
  case context.display_name {
    Some(name) -> name
    None -> context.email
  }
}

pub fn normalize_email(email: String) -> String {
  email
  |> string.trim
  |> string.lowercase
}

pub fn normalize_display_name(name: String) -> Option(String) {
  case string.trim(name) {
    "" -> None
    trimmed -> Some(trimmed)
  }
}
