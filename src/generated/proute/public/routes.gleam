//// Generated. Do not edit.
////
//// mount: public
//// pages: src/public/pages
//// route_root: /

import gleam/bool
import gleam/string
import gleam/uri

/// Public routes generated from `src/public/pages`.
///
/// These constructors are the stable vocabulary callers use instead of
/// passing raw strings around. If a page file disappears, callers using
/// its constructor or helper should fail at compile time.
pub type Route {
  Home
  Games
  GamesId(id: String)
  SignIn
  Standings
  TeamsSlug(slug: String)
  NotFound
}

/// Parse a request path into the public route tree.
///
/// The input may include a query string or fragment; both are ignored.
/// Dynamic path parameters are percent-decoded after path segmentation,
/// so encoded slashes stay inside the parameter value. Invalid percent
/// encoding in a dynamic segment returns `NotFound`.
pub fn parse_path(raw: String) -> Route {
  let without_query = case string.split(raw, "?") {
    [path, ..] -> path
    [] -> raw
  }
  let without_fragment = case string.split(without_query, "#") {
    [path, ..] -> path
    [] -> without_query
  }
  parse(uri.path_segments(without_fragment))
}

fn parse(segments: List(String)) -> Route {
  case segments {
    [] -> Home
    ["games"] -> Games
    ["games", id] ->
      case percent_decode(id) {
        Ok(id) -> GamesId(id:)
        Error(Nil) -> NotFound
      }
    ["sign_in"] -> SignIn
    ["standings"] -> Standings
    ["teams", slug] ->
      case percent_decode(slug) {
        Ok(slug) -> TeamsSlug(slug:)
        Error(Nil) -> NotFound
      }
    ["not_found"] -> NotFound
    _ -> NotFound
  }
}

/// Convert a public route value into its canonical path.
///
/// Dynamic parameters are percent-encoded.
/// `NotFound` points to the canonical not-found path declared by
/// `not_found_.gleam`, which keeps 404 links from pretending to be the
/// public homepage.
pub fn route_to_path(route: Route) -> String {
  case route {
    Home -> "/"
    Games -> "/games"
    GamesId(id:) -> "/games/" <> uri.percent_encode(id)
    SignIn -> "/sign_in"
    Standings -> "/standings"
    TeamsSlug(slug:) -> "/teams/" <> uri.percent_encode(slug)
    NotFound -> "/not_found"
  }
}

/// Build an absolute URL for a public route.
///
/// `origin` must be the explicit scheme and authority, such as
/// `https://example.com` or `http://localhost:8080`. One trailing slash is
/// trimmed before appending the route path. The generated module does not
/// guess the origin from request headers because that policy belongs to the app.
pub fn route_to_url(route route: Route, origin origin: String) -> String {
  trim_trailing_slash(origin) <> route_to_path(route)
}

/// Construct the public homepage route.
pub fn home_route() -> Route {
  Home
}

/// Build the home path.
pub fn home_path() -> String {
  route_to_path(home_route())
}

/// Build an absolute URL for the public homepage route.
pub fn home_url(origin origin: String) -> String {
  route_to_url(route: home_route(), origin:)
}

/// Construct the games route.
pub fn games_route() -> Route {
  Games
}

/// Build the games path.
pub fn games_path() -> String {
  route_to_path(games_route())
}

/// Build an absolute URL for the games route.
pub fn games_url(origin origin: String) -> String {
  route_to_url(route: games_route(), origin:)
}

/// Construct the games id route.
pub fn games_id_route(id id: String) -> Route {
  GamesId(id:)
}

/// Build the games id path, percent-encoding `id`.
pub fn games_id_path(id id: String) -> String {
  route_to_path(games_id_route(id:))
}

/// Build an absolute URL for the games id route.
pub fn games_id_url(id id: String, origin origin: String) -> String {
  route_to_url(route: games_id_route(id:), origin:)
}

/// Construct the sign in route.
pub fn sign_in_route() -> Route {
  SignIn
}

/// Build the sign in path.
pub fn sign_in_path() -> String {
  route_to_path(sign_in_route())
}

/// Build an absolute URL for the sign in route.
pub fn sign_in_url(origin origin: String) -> String {
  route_to_url(route: sign_in_route(), origin:)
}

/// Construct the standings route.
pub fn standings_route() -> Route {
  Standings
}

/// Build the standings path.
pub fn standings_path() -> String {
  route_to_path(standings_route())
}

/// Build an absolute URL for the standings route.
pub fn standings_url(origin origin: String) -> String {
  route_to_url(route: standings_route(), origin:)
}

/// Construct the teams slug route.
pub fn teams_slug_route(slug slug: String) -> Route {
  TeamsSlug(slug:)
}

/// Build the teams slug path, percent-encoding `slug`.
pub fn teams_slug_path(slug slug: String) -> String {
  route_to_path(teams_slug_route(slug:))
}

/// Build an absolute URL for the teams slug route.
pub fn teams_slug_url(slug slug: String, origin origin: String) -> String {
  route_to_url(route: teams_slug_route(slug:), origin:)
}

/// Construct the public not-found route.
pub fn not_found_route() -> Route {
  NotFound
}

/// Build the canonical public not-found path.
pub fn not_found_path() -> String {
  route_to_path(not_found_route())
}

/// Build an absolute URL for the public not-found route.
pub fn not_found_url(origin origin: String) -> String {
  route_to_url(route: not_found_route(), origin:)
}

fn percent_decode(value: String) -> Result(String, Nil) {
  case uri.percent_decode(value) {
    Ok(decoded) -> Ok(decoded)
    Error(_) -> Error(Nil)
  }
}

fn trim_trailing_slash(origin: String) -> String {
  use <- bool.guard(
    when: string.ends_with(origin, "/") == False,
    return: origin,
  )
  string.drop_end(origin, 1)
}
