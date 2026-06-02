@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import generated/api/to_client_codec
@target(erlang)
import generated/api/to_server_codec

@target(erlang)
pub type ClientRequest {
  ClientRequest(module: String, request_id: Int, message: ToServer)
}

@target(erlang)
pub fn ensure() -> Nil {
  let _ = to_server_codec.ensure()
  to_client_codec.ensure()
}

@target(erlang)
pub fn decode(bytes: BitArray) -> Result(ToServer, Nil) {
  to_server_codec.decode(bytes)
}

@target(erlang)
pub fn decode_request(bytes: BitArray) -> Result(ClientRequest, Nil) {
  case decode_any(bytes) {
    Ok(#(module, request_id, message))
      if request_id >= 0 && request_id <= 4_294_967_295
    -> Ok(ClientRequest(module:, request_id:, message:))
    _ -> Error(Nil)
  }
}

@target(erlang)
pub fn encode(message: ToClient) -> BitArray {
  to_client_codec.encode(message)
}

@target(erlang)
pub fn encode_response(
  request_id request_id: Int,
  message message: ToClient,
) -> BitArray {
  let assert True = request_id >= 0 && request_id <= 4_294_967_295
  let payload = to_client_codec.encode(message)
  <<0, request_id:32, payload:bits>>
}

@target(erlang)
pub fn encode_push(
  module module: String,
  message message: ToClient,
) -> BitArray {
  let payload = encode_any(#(module, message))
  <<1, payload:bits>>
}

@target(erlang)
@external(erlang, "to_server_codec_ffi", "decode")
fn decode_any(_bytes: BitArray) -> Result(a, Nil) {
  panic as "generated/api/server.decode_any external missing"
}

@target(erlang)
@external(erlang, "to_client_codec_ffi", "encode")
fn encode_any(_value: a) -> BitArray {
  panic as "generated/api/server.encode_any external missing"
}
