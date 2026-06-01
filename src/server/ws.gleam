@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import generated/api/server as generated_server
@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/erlang/atom
@target(erlang)
import gleam/erlang/process.{type Selector}
@target(erlang)
import gleam/list
@target(erlang)
import gleam/option.{type Option, Some}
@target(erlang)
import gleam/result
@target(erlang)
import mist.{type Next, type WebsocketConnection, type WebsocketMessage}
@target(erlang)
import server/api
@target(erlang)
import server/topics
@target(erlang)
import sqlight

@target(erlang)
pub type State {
  State(db: sqlight.Connection, admin_authorized: Bool)
}

@target(erlang)
pub fn on_init(
  _conn: WebsocketConnection,
  db: sqlight.Connection,
  admin_authorized: Bool,
) -> #(State, Option(Selector(BitArray))) {
  topics.start()
  topics.join("app")
  let selector =
    process.new_selector()
    |> process.select_record(
      tag: atom.create("scoreboard_frame"),
      fields: 1,
      mapping: fn(msg) {
        msg
        |> decode.run(decode.at([1], decode.bit_array))
        |> result.unwrap(<<>>)
      },
    )
  #(State(db: db, admin_authorized:), Some(selector))
}

@target(erlang)
pub fn on_close(_state: State) -> Nil {
  Nil
}

@target(erlang)
pub fn handler(
  state state: State,
  msg msg: WebsocketMessage(BitArray),
  conn conn: WebsocketConnection,
) -> Next(State, BitArray) {
  case msg {
    mist.Binary(data) -> {
      handle_client_frame(state: state, conn: conn, data: data)
      mist.continue(state)
    }
    mist.Custom(frame) -> {
      let _sent = mist.send_binary_frame(conn, frame)
      mist.continue(state)
    }
    mist.Text(_) -> mist.continue(state)
    mist.Closed -> mist.stop()
    mist.Shutdown -> mist.stop()
  }
}

@target(erlang)
fn handle_client_frame(
  state state: State,
  conn conn: WebsocketConnection,
  data data: BitArray,
) -> Nil {
  case generated_server.decode_request(data) {
    Ok(generated_server.ClientRequest(
      request_id: request_id,
      message: message,
      ..,
    )) -> {
      let replies =
        api.dispatch(
          db: state.db,
          message: message,
          admin_authorized: state.admin_authorized,
        )
      list.each(replies, fn(reply) {
        let response = generated_server.encode_response(request_id, reply)
        let _sent = mist.send_binary_frame(conn, response)
        broadcast_if_live_update(reply)
      })
    }
    Error(Nil) -> Nil
  }
}

@target(erlang)
fn broadcast_if_live_update(message: ToClient) -> Nil {
  case message {
    to_client.GameUpdated(_) ->
      topics.broadcast("app", api.push(module: "app", message: message))
    _ -> Nil
  }
}
