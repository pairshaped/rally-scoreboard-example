//// Generated. Do not edit.
////
//// Route parser and path builder for this client app.
//// Derived from the discovered page routes and the shared Route type from
//// generated/public/route.

import generated/public/route.{type Route}
import gleam/result
import gleam/uri.{type Uri}
import lustre/attribute.{type Attribute}

pub fn parse_uri(uri: Uri) -> Route {
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

pub fn route_to_path(route route: Route) -> String {
  case route {
    route.Games -> "/games"
    route.GamesId(id:) -> "/games/" <> uri.percent_encode(id)
    route.Standings -> "/standings"
    route.Team(slug:) -> "/teams/" <> uri.percent_encode(slug)
    route.NotFound -> "/"
  }
}

pub fn href(route route: Route) -> Attribute(msg) {
  attribute.href(route_to_path(route:))
}
