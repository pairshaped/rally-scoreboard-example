//// Generated. Do not edit.
////
//// WebSocket adapter for the admin Mount.
//// Derived from this Mount's routes, generated request context,
//// server/admin/backend.gleam, and server/admin/model.gleam.
//// The shared ws_runtime owns framing. This file binds it to the
//// Mount-specific route and backend code.
////
//// Admin sockets also read the session cookie so RequestContext can include
//// the authenticated user. Sign-in pages do not create this socket.
////
//// Admin game sockets join the live-update scope so multiple open score desks
//// receive each other's score changes through the same ToClient broadcast lane.

import generated/admin/request_context.{type RequestContext, RequestContext}
import generated/admin/route
import generated/protocol_wire
import generated/runtime/effect_state
import generated/runtime/live_updates
import generated/ws_runtime
import gleam/dict
import gleam/dynamic
import gleam/erlang/process
import gleam/option.{None, Some}
import lustre/effect.{type Effect}
import mist.{type WebsocketConnection, type WebsocketMessage}
import server/admin/authentication
import server/admin/backend
import server/admin/model.{type Model}
import server/server_context.{type ServerContext}
import shared/api/to_client.{type ToClient}
import shared/api/to_server.{type ToServer}

pub fn on_init(
  conn conn: WebsocketConnection,
  server_context server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  cookie_header cookie_header: Result(String, Nil),
) -> #(Nil, option.Option(process.Selector(dynamic.Dynamic))) {
  live_updates.join()
  effect_state.put_ws_cookie_header(case cookie_header {
    Ok(h) -> h
    Error(Nil) -> ""
  })
  ws_runtime.on_init(
    conn:,
    server_context:,
    session_id:,
    hostname:,
    init_backend: backend.init,
  )
}

pub fn on_close(state: Nil) -> Nil {
  live_updates.leave()
  ws_runtime.on_close(state)
}

pub fn handler(
  state state: Nil,
  msg msg: WebsocketMessage(a),
  conn conn: WebsocketConnection,
) -> mist.Next(Nil, a) {
  ws_runtime.handler(
    state:,
    msg:,
    conn:,
    build_route:,
    make_request_context:,
    handle_to_server:,
    handle_custom: fn(msg) {
      let update: ToClient = protocol_wire.coerce(msg)
      Some(protocol_wire.encode_to_client(update))
    },
  )
}

fn make_request_context(
  route route: route.Route,
  session_id session_id: String,
  hostname hostname: String,
  query query: dict.Dict(String, String),
) -> RequestContext {
  let user_id = {
    let cookie = effect_state.get_ws_cookie_header()
    case cookie {
      "" -> None
      h -> authentication.authenticated_user_id(Ok(h), session_id)
    }
  }
  RequestContext(route:, query:, session_id:, user_id:, hostname:)
}

fn handle_to_server(
  msg msg: ToServer,
  request_context request_context: RequestContext,
  backend_model backend_model: Model,
  server_context server_context: ServerContext,
) -> #(Model, Effect(ToClient)) {
  backend.update(
    backend.FromClient(msg, request_context),
    backend_model,
    server_context,
  )
}

fn build_route(page: String, _value: dynamic.Dynamic) -> route.Route {
  case page {
    "AdminGames" -> route.AdminGames
    _ -> route.NotFound
  }
}
