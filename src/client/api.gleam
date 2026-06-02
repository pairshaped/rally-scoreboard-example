@target(javascript)
import api/to_server.{type ToServer}
@target(javascript)
import generated/api/client as generated_client
@target(javascript)
import lustre/effect.{type Effect}

@target(javascript)
pub fn connect(
  url url: String,
  on_frame on_frame: fn(BitArray) -> msg,
) -> Effect(msg) {
  effect.from(fn(dispatch) {
    connect_socket(url, fn(frame) { dispatch(on_frame(frame)) })
  })
}

@target(javascript)
pub fn send(module module: String, message message: ToServer) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let frame = generated_client.encode_request(module, message)
    send_frame(frame)
  })
}

@target(javascript)
@external(javascript, "./api_ffi.mjs", "connect")
fn connect_socket(_url: String, _on_frame: fn(BitArray) -> Nil) -> Nil {
  Nil
}

@target(javascript)
@external(javascript, "./api_ffi.mjs", "send_frame")
fn send_frame(_frame: BitArray) -> Nil {
  Nil
}
