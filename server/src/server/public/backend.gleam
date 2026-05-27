//// Public backend state and update loop.
////
//// Mirrors Lamdera-style server state for the public Mount: the generated
//// WebSocket runtime sends ToServer messages here, then this module delegates
//// constructor dispatch to generated public code.

import generated/public/dispatch as generated_dispatch
import generated/public/request_context.{type RequestContext}
import lustre/effect.{type Effect}
import server/public/model.{type Model, Model}
import server/server_context.{type ServerContext}
import shared/api/to_client.{type ToClient}
import shared/api/to_server.{type ToServer}

pub type Msg {
  FromClient(ToServer, RequestContext)
  SessionConnected
  SessionDisconnected
}

pub fn init() -> Model {
  Model
}

pub fn update(
  msg msg: Msg,
  model model: Model,
  server_context server_context: ServerContext,
) -> #(Model, Effect(ToClient)) {
  case msg {
    FromClient(to_server_msg, request_context) ->
      generated_dispatch.to_server(
        msg: to_server_msg,
        request_context:,
        server_context:,
        backend_model: model,
      )
    SessionConnected -> #(model, effect.none())
    SessionDisconnected -> #(model, effect.none())
  }
}
