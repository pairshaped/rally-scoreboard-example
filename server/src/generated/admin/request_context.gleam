//// Generated. Do not edit.
////
//// Request metadata passed from the WebSocket runtime into ToServer handlers.
//// Derived from the shared route module generated/admin/route.

import generated/admin/route.{type Route}
import gleam/dict.{type Dict}
import gleam/option.{type Option}

pub type RequestContext {
  RequestContext(
    route: Route,
    query: Dict(String, String),
    session_id: String,
    user_id: Option(Int),
    hostname: String,
  )
}
