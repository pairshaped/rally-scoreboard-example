//// Generated. Do not edit.
////
//// Request metadata passed from the WebSocket runtime into ToServer handlers.
//// Derived from generated/public/route, the HTTP request URI, and the
//// runtime session cookie.
////
//// ToServer constructors carry command data only. Route, query, session,
//// user, and host facts are supplied through this generated context.

import generated/public/route.{type Route}
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
