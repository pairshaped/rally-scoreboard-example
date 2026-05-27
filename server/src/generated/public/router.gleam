//// Generated. Do not edit.
////
//// Server route parser for the public Mount.
//// Derived from server/public/pages route modules and [[tools.rally.clients]].

import generated/public/route.{type Route}
import gleam/result
import gleam/uri.{type Uri}

pub fn parse_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> route.Games
    ["games"] -> route.Games
    ["games", id] ->
      route.GamesId(id: result.unwrap(uri.percent_decode(id), id))
    ["standings"] -> route.Standings
    ["teams", slug] ->
      route.Team(slug: result.unwrap(uri.percent_decode(slug), slug))
    _ -> route.NotFound
  }
}
