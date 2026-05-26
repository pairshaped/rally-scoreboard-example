//// Generated. Do not edit.
////
//// Server route parser for the public Mount.
//// Derived from server/public/pages route modules and [[tools.rally.clients]].

import gleam/result
import gleam/uri.{type Uri}

pub type Route {
  Games
  GamesId(id: String)
  Standings
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Games
    ["games"] -> Games
    ["games", id] -> GamesId(id: result.unwrap(uri.percent_decode(id), id))
    ["standings"] -> Standings
    _ -> NotFound(uri:)
  }
}
