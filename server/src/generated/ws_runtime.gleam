//// Generated. Do not edit.
////
//// Shared WebSocket runtime for root API Mounts.
//// Derived from the Generator Framework's root API transport contract. Mount-specific
//// ws_handler modules inject route building, request-context creation,
//// backend init, and ToServer handling callbacks.
////
//// This module owns frame decoding, page_init handling, backend model storage,
//// effect execution, and ToClient push encoding. It is generated once because
//// those behaviors are transport-wide rather than Mount-specific.

import generated/protocol_wire
import generated/runtime/effect_runner
import generated/runtime/effect_state
import generated/runtime/env
import gleam/bit_array
import gleam/bool
import gleam/dict
import gleam/dynamic
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/effect.{type Effect}
import mist.{type WebsocketConnection, type WebsocketMessage}
import server/server_context.{type ServerContext}
import shared/api/to_client.{type ToClient}
import shared/api/to_server.{type ToServer}

type ToServerContextError {
  MissingServerContext
  MissingRequestContext
  MissingBackendModel
}

/// Store per-socket server state and create the backend model.
/// The Mount adapter supplies init_backend from server/{mount_namespace}/backend.
pub fn on_init(
  conn conn: WebsocketConnection,
  server_context server_context: ServerContext,
  session_id session_id: String,
  hostname hostname: String,
  init_backend init_backend: fn() -> model,
) -> #(Nil, Option(process.Selector(dynamic.Dynamic))) {
  let Nil = effect_state.put_ws_state(conn, server_context, "")
  let Nil = effect_state.put_ws_session(session_id)
  let Nil = effect_state.put_ws_hostname(hostname)
  let backend_model = init_backend()
  let Nil = effect_state.put_backend_model(backend_model)
  let selector =
    process.new_selector()
    |> process.select_other(fn(msg) { msg })
  #(Nil, Some(selector))
}

pub fn on_close(_state: Nil) -> Nil {
  Nil
}

/// Decode browser frames and route them through the root API contract.
/// page_init frames establish RequestContext. to_server frames update the
/// backend model and turn emitted ToClient values into push frames.
pub fn handler(
  state state: Nil,
  msg msg: WebsocketMessage(a),
  conn conn: WebsocketConnection,
  build_route build_route: fn(String, dynamic.Dynamic) -> route,
  make_request_context make_request_context: fn(
    route,
    String,
    String,
    dict.Dict(String, String),
  ) -> request_context,
  handle_to_server handle_to_server: fn(
    ToServer,
    request_context,
    model,
    ServerContext,
  ) -> #(model, Effect(ToClient)),
  handle_custom handle_custom: fn(a) -> Option(BitArray),
) -> mist.Next(Nil, a) {
  debug_log("[runtime:ws] handler called")
  case msg {
    mist.Binary(data) ->
      handle_binary(
        state:,
        data:,
        conn:,
        build_route:,
        make_request_context:,
        handle_to_server:,
      )
    mist.Custom(msg) ->
      case handle_custom(msg) {
        Some(frame) -> {
          let _send_result = mist.send_binary_frame(conn, frame)
          mist.continue(state)
        }
        None -> mist.continue(state)
      }
    mist.Closed -> mist.stop()
    mist.Shutdown -> mist.stop()
    _ -> mist.continue(state)
  }
}

fn handle_binary(
  state state: Nil,
  data data: BitArray,
  conn conn: WebsocketConnection,
  build_route build_route: fn(String, dynamic.Dynamic) -> route,
  make_request_context make_request_context: fn(
    route,
    String,
    String,
    dict.Dict(String, String),
  ) -> request_context,
  handle_to_server handle_to_server: fn(
    ToServer,
    request_context,
    model,
    ServerContext,
  ) -> #(model, Effect(ToClient)),
) -> mist.Next(Nil, a) {
  debug_log(
    "[runtime:ws] Binary frame: "
    <> int.to_string(bit_array.byte_size(data))
    <> " bytes",
  )
  case protocol_wire.decode_request(data) {
    Ok(#(page, request_id, value)) if request_id == 0 ->
      handle_page_init(
        state:,
        conn:,
        page:,
        request_id:,
        value:,
        build_route:,
        make_request_context:,
      )
    Ok(#("to_server", _request_id, _value)) ->
      handle_to_server_frame(state:, data:, conn:, handle_to_server:)
    Ok(#(_module, _request_id, _value)) -> {
      debug_log("[runtime:ws] unknown module in request")
      mist.continue(state)
    }
    Error(reason) -> {
      debug_log(
        "[runtime:ws] decode_request failed: " <> string.inspect(reason),
      )
      mist.continue(state)
    }
  }
}

fn handle_page_init(
  state state: Nil,
  conn conn: WebsocketConnection,
  page page: String,
  request_id request_id: Int,
  value value: dynamic.Dynamic,
  build_route build_route: fn(String, dynamic.Dynamic) -> route,
  make_request_context make_request_context: fn(
    route,
    String,
    String,
    dict.Dict(String, String),
  ) -> request_context,
) -> mist.Next(Nil, a) {
  debug_log("[runtime:ws] page_init: " <> page)
  case effect_state.get_stored_server_context() {
    Error(Nil) -> {
      io.println_error(
        "[runtime:ws] missing server_context; failing page_init for " <> page,
      )
      let response_frame =
        protocol_wire.encode_response(
          request_id:,
          value: Error("server_unavailable"),
        )
      let _send_result = mist.send_binary_frame(conn, response_frame)
      send_pending_frames(conn)
      mist.continue(state)
    }
    Ok(server_context) -> {
      let Nil = effect_state.put_ws_state(conn, server_context, page)

      let #(route_param, query) = split_page_init_value(value)
      let route = build_route(page, route_param)
      let request_context =
        make_request_context(
          route,
          effect_state.get_ws_session(),
          effect_state.get_ws_hostname(),
          query,
        )
      let Nil = effect_state.put_ws_request_context(request_context)

      let response_frame =
        protocol_wire.encode_response(request_id:, value: Nil)
      let _send_result = mist.send_binary_frame(conn, response_frame)
      send_pending_frames(conn)
      mist.continue(state)
    }
  }
}

fn split_page_init_value(
  value: dynamic.Dynamic,
) -> #(dynamic.Dynamic, dict.Dict(String, String)) {
  let list_value: List(dynamic.Dynamic) = protocol_wire.coerce(value)
  case list_value {
    [route_param, query_dynamic] -> {
      let query: dict.Dict(String, String) = protocol_wire.coerce(query_dynamic)
      #(route_param, query)
    }
    _ -> #(value, dict.new())
  }
}

fn handle_to_server_frame(
  state state: Nil,
  data data: BitArray,
  conn conn: WebsocketConnection,
  handle_to_server handle_to_server: fn(
    ToServer,
    request_context,
    model,
    ServerContext,
  ) -> #(model, Effect(ToClient)),
) -> mist.Next(Nil, a) {
  debug_log("[runtime:ws] to_server command")
  case protocol_wire.decode_to_server(data) {
    Error(reason) -> {
      io.println_error(
        "[runtime:ws] failed to decode ToServer frame: "
        <> string.inspect(reason),
      )
      mist.continue(state)
    }
    Ok(to_server_msg) ->
      dispatch_to_server(state:, conn:, to_server_msg:, handle_to_server:)
  }
}

fn dispatch_to_server(
  state state: Nil,
  conn conn: WebsocketConnection,
  to_server_msg to_server_msg: ToServer,
  handle_to_server handle_to_server: fn(
    ToServer,
    request_context,
    model,
    ServerContext,
  ) -> #(model, Effect(ToClient)),
) -> mist.Next(Nil, a) {
  case load_to_server_context() {
    Error(reason) -> {
      io.println_error(to_server_context_error_message(reason))
      mist.continue(state)
    }
    Ok(#(server_context, request_context, backend_model)) -> {
      let #(new_backend_model, to_client_effect) =
        handle_to_server(
          to_server_msg,
          request_context,
          backend_model,
          server_context,
        )
      let Nil = effect_state.put_backend_model(new_backend_model)
      effect_runner.run_to_client_effect(to_client_effect, fn(client_msg) {
        let frame = protocol_wire.encode_to_client(client_msg)
        effect_state.push_outgoing_frame(frame)
      })
      send_pending_frames(conn)
      mist.continue(state)
    }
  }
}

fn load_to_server_context() -> Result(
  #(ServerContext, request_context, model),
  ToServerContextError,
) {
  case effect_state.get_stored_server_context() {
    Error(Nil) -> Error(MissingServerContext)
    Ok(server_context) -> load_request_context(server_context:)
  }
}

fn load_request_context(
  server_context server_context: ServerContext,
) -> Result(#(ServerContext, request_context, model), ToServerContextError) {
  case effect_state.get_ws_request_context() {
    Error(Nil) -> Error(MissingRequestContext)
    Ok(request_context) -> load_backend_model(server_context:, request_context:)
  }
}

fn load_backend_model(
  server_context server_context: ServerContext,
  request_context request_context: request_context,
) -> Result(#(ServerContext, request_context, model), ToServerContextError) {
  case effect_state.get_backend_model() {
    Error(Nil) -> Error(MissingBackendModel)
    Ok(backend_model) -> Ok(#(server_context, request_context, backend_model))
  }
}

fn to_server_context_error_message(error: ToServerContextError) -> String {
  case error {
    MissingServerContext ->
      "[runtime:ws] missing server_context; dropping ToServer"
    MissingRequestContext ->
      "[runtime:ws] missing request_context; dropping ToServer"
    MissingBackendModel ->
      "[runtime:ws] missing backend_model; dropping ToServer"
  }
}

fn send_pending_frames(conn: WebsocketConnection) -> Nil {
  let frames = effect_state.drain_outgoing_frames()
  list.each(frames, fn(frame) {
    let _send_result = mist.send_binary_frame(conn, frame)
    Nil
  })
}

fn debug_log(message: String) -> Nil {
  use <- bool.guard(when: !env.is_dev(), return: Nil)
  io.println_error(message)
}
