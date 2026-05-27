//// Generated. Do not edit.
////
//// Server route parser for the admin Mount.
//// Derived from server/admin/pages route modules and [[tools.rally.clients]].

import generated/admin/route.{type Route}
import gleam/uri.{type Uri}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["admin", "sign_in"] -> route.AdminSignInPassword
    ["admin", "sign_in", "password"] -> route.AdminSignInPassword
    ["admin", "sign_in", "code"] -> route.AdminSignInCode
    ["admin", "games"] -> route.AdminGames
    _ -> route.NotFound
  }
}
