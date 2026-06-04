@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server.{type ToServer}
@target(erlang)
import generated/libero/result.{type ApiLoadError, type ApiSaveError}
@target(erlang)
import generated/libero/to_client_codec
@target(erlang)
import generated/libero/to_server_codec

@target(erlang)
pub type ClientRequest {
  ClientRequest(request_id: Int, module: String, message: ToServer)
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
    Ok(#(request_id, module, message)) ->
      Ok(ClientRequest(request_id:, module:, message:))
    _ -> Error(Nil)
  }
}

@target(erlang)
pub fn encode(message: ToClient) -> BitArray {
  to_client_codec.encode(message)
}

@target(erlang)
pub fn encode_response(message message: ToClient) -> BitArray {
  let payload = to_client_codec.encode(message)
  <<0, payload:bits>>
}

@target(erlang)
pub fn encode_load_result(
  request_id request_id: Int,
  result result: Result(ToClient, List(ApiLoadError)),
) -> BitArray {
  encode_result_frame(request_id, result)
}

@target(erlang)
pub fn encode_save_result(
  request_id request_id: Int,
  result result: Result(Nil, List(ApiSaveError)),
) -> BitArray {
  encode_result_frame(request_id, result)
}

@target(erlang)
fn encode_result_frame(request_id: Int, result: a) -> BitArray {
  let payload = encode_any(#(request_id, result))
  <<2, payload:bits>>
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
  panic as "generated/libero/server.decode_any external missing"
}

@target(erlang)
@external(erlang, "to_client_codec_ffi", "encode")
fn encode_any(_value: a) -> BitArray {
  panic as "generated/libero/server.encode_any external missing"
}
