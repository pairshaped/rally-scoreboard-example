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
  Team(slug: String)
  NotFound(uri: Uri)
}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Games
    ["games"] -> Games
    ["games", id] -> GamesId(id: result.unwrap(uri.percent_decode(id), id))
    ["standings"] -> Standings
    ["teams", slug] -> Team(slug: result.unwrap(uri.percent_decode(slug), slug))
    _ -> NotFound(uri:)
  }
}
