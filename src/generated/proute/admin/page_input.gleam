//// Generated page input types. Do not edit.
////
//// mount: admin
////
//// The admin routes currently have no dynamic route params, but page dispatch
//// still receives query params through the same generated input convention as
//// other mounts.

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
