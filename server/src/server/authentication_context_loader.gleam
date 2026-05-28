//// Loads an AuthenticationContext from a user_id.
////
//// App-owned loader called by the generated entry and WebSocket handlers.
//// In a real app this would query the users table. Scoreboard uses
//// hardcoded demo users per ADR 0008.

import gleam/option.{type Option, None, Some}
import shared/authentication_context.{
  type AuthenticationContext, AuthenticationContext,
}

pub fn from_user_id(user_id: Int) -> Option(AuthenticationContext) {
  case user_id {
    1 ->
      Some(AuthenticationContext(
        user_id: 1,
        email: "admin@example.com",
        display_name: None,
      ))
    2 ->
      Some(AuthenticationContext(
        user_id: 2,
        email: "fan@example.com",
        display_name: Some("Fan"),
      ))
    _ -> None
  }
}
