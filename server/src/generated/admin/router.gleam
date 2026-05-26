//// Generated. Do not edit.
////
//// Server route parser for the admin Mount.
//// Derived from server/admin/pages route modules and [[tools.rally.clients]].

import gleam/uri.{type Uri}

pub type Route {
  AdminSignInPassword
  AdminSignInCode
  AdminGames
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["admin", "sign_in"] -> AdminSignInPassword
    ["admin", "sign_in", "password"] -> AdminSignInPassword
    ["admin", "sign_in", "code"] -> AdminSignInCode
    ["admin", "games"] -> AdminGames
    _ -> NotFound(uri:)
  }
}
