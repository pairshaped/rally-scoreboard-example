//// Generated page input types. Do not edit.
////
//// mount: public
////
//// Pages receive route parameters and query parameters as named values instead
//// of a growing list of positional arguments. Nested dynamic routes can add
//// fields to the route params record without changing the meaning of call sites.

/// Query parameters parsed from the current URL.
///
/// Query strings are open-ended and can repeat keys, so generated code stores
/// the decoded pairs instead of forcing a fixed record shape.
pub type QueryParams {
  QueryParams(values: List(#(String, String)))
}

/// Build an empty query param bag.
pub fn empty_query_params() -> QueryParams {
  QueryParams([])
}

/// Route parameters for `pages/games/id_.gleam`.
pub type GamesIdRouteParams {
  GamesIdRouteParams(id: String)
}

/// Route parameters for `pages/teams/slug_.gleam`.
pub type TeamsSlugRouteParams {
  TeamsSlugRouteParams(slug: String)
}
