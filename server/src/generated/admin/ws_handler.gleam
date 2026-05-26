//// Generated. Do not edit.
////
//// WebSocket adapter for the admin Mount.
//// Derived from this Mount's routes, generated request context,
//// server/admin/backend.gleam, and server/admin/model.gleam.
//// The shared ws_runtime owns framing. This file binds it to the
//// Mount-specific route and backend code.

import generated/admin/request_context.{type RequestContext, RequestContext}
import generated/admin/route
import generated/ws_runtime
import gleam/dict
import gleam/dynamic
import gleam/erlang/process
import gleam/option
import lustre/effect.{type Effect}
import mist.{type WebsocketConnection, type WebsocketMessage}
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
) -> #(Nil, option.Option(process.Selector(dynamic.Dynamic))) {
  ws_runtime.on_init(
    conn:,
    server_context:,
    session_id:,
    hostname:,
    init_backend: backend.init,
  )
}

pub fn on_close(state: Nil) -> Nil {
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
  )
}

fn make_request_context(
  route route: route.Route,
  session_id session_id: String,
  hostname hostname: String,
) -> RequestContext {
  RequestContext(
    route:,
    query: dict.new(),
    session_id:,
    user_id: option.None,
    hostname:,
  )
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
