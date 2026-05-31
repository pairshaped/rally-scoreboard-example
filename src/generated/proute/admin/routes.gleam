//// Generated. Do not edit.
////
//// mount: admin
//// pages: src/admin/pages
//// route_root: /admin

import gleam/bool
import gleam/string
import gleam/uri

/// Admin routes generated from `src/admin/pages`.
///
/// These constructors are the stable vocabulary callers use instead of
/// passing raw strings around. If a page file disappears, callers using
/// its constructor or helper should fail at compile time.
pub type Route {
  AdminHome
  AdminGames
  NotFound
}

/// Parse a request path into the admin route tree.
///
/// The input may include a query string or fragment; both are ignored.
/// The path must be rooted at `/admin`; paths outside that mount return `NotFound`.
/// This lets each
/// mount own its own route tree without knowing about sibling mounts.
pub fn parse_path(raw: String) -> Route {
  let without_query = case string.split(raw, "?") {
    [path, ..] -> path
    [] -> raw
  }
  let without_fragment = case string.split(without_query, "#") {
    [path, ..] -> path
    [] -> without_query
  }
  let segments = uri.path_segments(without_fragment)

  case segments {
    ["admin", ..rest] -> parse(rest)
    _ -> NotFound
  }
}

fn parse(segments: List(String)) -> Route {
  case segments {
    [] -> AdminHome
    ["games"] -> AdminGames
    ["not_found"] -> NotFound
    _ -> NotFound
  }
}

/// Convert an admin route value into its canonical path.
///
/// `NotFound` points to the canonical not-found path declared by
/// `not_found_.gleam`, which keeps 404 links from pretending to be the
/// admin homepage.
pub fn route_to_path(route: Route) -> String {
  case route {
    AdminHome -> "/admin"
    AdminGames -> "/admin/games"
    NotFound -> "/admin/not_found"
  }
}

/// Build an absolute URL for an admin route.
///
/// `origin` must be the explicit scheme and authority, such as
/// `https://example.com` or `http://localhost:8080`. One trailing slash is
/// trimmed before appending the route path. The generated module does not
/// guess the origin from request headers because that policy belongs to the app.
pub fn route_to_url(route route: Route, origin origin: String) -> String {
  trim_trailing_slash(origin) <> route_to_path(route)
}

/// Construct the admin homepage route.
pub fn admin_home_route() -> Route {
  AdminHome
}

/// Build the admin home path.
pub fn admin_home_path() -> String {
  route_to_path(admin_home_route())
}

/// Build an absolute URL for the admin homepage route.
pub fn admin_home_url(origin origin: String) -> String {
  route_to_url(route: admin_home_route(), origin:)
}

/// Construct the admin games route.
pub fn admin_games_route() -> Route {
  AdminGames
}

/// Build the admin games path.
pub fn admin_games_path() -> String {
  route_to_path(admin_games_route())
}

/// Build an absolute URL for the admin games route.
pub fn admin_games_url(origin origin: String) -> String {
  route_to_url(route: admin_games_route(), origin:)
}

/// Construct the admin not-found route.
pub fn not_found_route() -> Route {
  NotFound
}

/// Build the canonical admin not-found path.
pub fn not_found_path() -> String {
  route_to_path(not_found_route())
}

/// Build an absolute URL for the admin not-found route.
pub fn not_found_url(origin origin: String) -> String {
  route_to_url(route: not_found_route(), origin:)
}

fn trim_trailing_slash(origin: String) -> String {
  use <- bool.guard(
    when: string.ends_with(origin, "/") == False,
    return: origin,
  )
  string.drop_end(origin, 1)
}
