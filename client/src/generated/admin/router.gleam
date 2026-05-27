//// Generated. Do not edit.
////
//// Browser-side route parser and path builder for the admin Mount.
//// Derived from the Mount route root (`/admin`), discovered page route
//// patterns, and the shared Route type from generated/admin/route.
////
//// Client shells use this module for Modem navigation and href generation.
//// It should stay in lockstep with server/src/generated/admin/router.gleam.

import generated/admin/route.{type Route}
import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}

pub fn parse_uri(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["admin", "sign_in"] -> route.AdminSignInPassword
    ["admin", "sign_in", "password"] -> route.AdminSignInPassword
    ["admin", "sign_in", "code"] -> route.AdminSignInCode
    ["admin", "games"] -> route.AdminGames
    _ -> route.NotFound
  }
}

pub fn route_to_path(route route: Route) -> String {
  case route {
    route.AdminSignInPassword -> "/admin/sign_in/password"
    route.AdminSignInCode -> "/admin/sign_in/code"
    route.AdminGames -> "/admin/games"
    route.NotFound -> "/"
  }
}

pub fn href(route route: Route) -> Attribute(msg) {
  attribute.href(route_to_path(route:))
}
