@target(javascript)
import api/to_server.{type ToServer}
@target(javascript)
import api/to_client.{type ToClient}
@target(javascript)
import generated/api/to_client_codec
@target(javascript)
import generated/api/to_server_codec

@target(javascript)
pub type ServerFrame {
  Response(request_id: Int, message: ToClient)
  Push(module: String, message: ToClient)
}

@target(javascript)
pub fn ensure() -> Nil {
  let _ = to_server_codec.ensure()
  to_client_codec.ensure()
}

@target(javascript)
pub fn send(message: ToServer) -> BitArray {
  to_server_codec.encode(message)
}

@target(javascript)
pub fn encode_request(
  module module: String,
  request_id request_id: Int,
  message message: ToServer,
) -> BitArray {
  let assert True = request_id >= 0 && request_id <= 4_294_967_295
  encode_any(#(module, request_id, message))
}

@target(javascript)
pub fn receive(bytes: BitArray) -> Result(ToClient, Nil) {
  to_client_codec.decode(bytes)
}

@target(javascript)
pub fn decode_server_frame(bytes: BitArray) -> Result(ServerFrame, Nil) {
  case bytes {
    <<0, request_id:32, payload:bits>> -> {
      case to_client_codec.decode(payload) {
        Ok(message) -> Ok(Response(request_id:, message:))
        Error(Nil) -> Error(Nil)
      }
    }
    <<1, payload:bits>> -> {
      case decode_any(payload) {
        Ok(#(module, message)) -> Ok(Push(module:, message:))
        Error(Nil) -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

@target(javascript)
@external(javascript, "./codec_ffi.mjs", "encode_value")
fn encode_any(_value: a) -> BitArray {
  panic as "generated/api/client.encode_any external missing"
}

@target(javascript)
@external(javascript, "./codec_ffi.mjs", "decode_result")
fn decode_any(_bytes: BitArray) -> Result(a, Nil) {
  panic as "generated/api/client.decode_any external missing"
}
