@target(erlang)
import app_auth
@target(erlang)
import generated/rally/server_ws
@target(erlang)
import gleam/erlang/process.{type Selector}
@target(erlang)
import gleam/option.{type Option}
@target(erlang)
import mist.{type Next, type WebsocketConnection, type WebsocketMessage}
@target(erlang)
import sqlight

@target(javascript)
/// JavaScript-side compile anchor for the websocket module.
/// Browser builds can import this module without pulling in Erlang-only code.
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
pub type State =
  server_ws.ConnectionState(app_auth.AuthenticatedUser)

@target(erlang)
/// Mist websocket init callback with Scoreboard load/auth context.
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_user: Option(app_auth.AuthenticatedUser),
) -> #(State, Option(Selector(BitArray))) {
  server_ws.on_init(load_context: db, admin_auth: admin_user)
}

@target(erlang)
pub fn on_close(state: State) -> Nil {
  server_ws.on_close(state)
}

@target(erlang)
pub fn handler(
  state state: State,
  msg msg: WebsocketMessage(BitArray),
  conn conn: WebsocketConnection,
) -> Next(State, BitArray) {
  server_ws.handler(state:, msg:, conn:)
}
