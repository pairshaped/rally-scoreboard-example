//// Loads an AuthenticationContext from the users table.
////
//// App-owned loader called by the generated entry and WebSocket handlers.
//// Queries the users table for normalized email and display_name.
//// can_access_admin is derived from the role column per the Scoreboard
//// authorization model (ADR 0008: authorization is app policy, not a
//// framework field).

import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import shared/authentication_context.{
  type AuthenticationContext, AuthenticationContext,
}
import sqlight

pub fn from_user_id(
  db db: sqlight.Connection,
  user_id user_id: Int,
) -> Option(AuthenticationContext) {
  let result =
    sqlight.query(
      "SELECT email, display_name FROM users WHERE id = ?1",
      on: db,
      with: [sqlight.int(user_id)],
      expecting: {
        use email <- decode.field(0, decode.string)
        use display_name <- decode.field(1, decode.optional(decode.string))
        decode.success(#(email, display_name))
      },
    )
  case result {
    Ok([#(email, display_name), ..]) ->
      Some(AuthenticationContext(user_id:, email:, display_name:))
    _ -> None
  }
}

pub fn can_access_admin(
  db db: sqlight.Connection,
  user_id user_id: Int,
) -> Bool {
  let result =
    sqlight.query(
      "SELECT role FROM users WHERE id = ?1",
      on: db,
      with: [sqlight.int(user_id)],
      expecting: {
        use role <- decode.field(0, decode.string)
        decode.success(role)
      },
    )
  case result {
    Ok([role, ..]) -> role == "admin"
    _ -> False
  }
}
