import api/to_server.{type ToServer}
import gleam/bit_array

pub fn ensure() -> Nil {
  ffi_ensure()
}

pub fn ensure_decoders() -> Nil {
  ensure()
}

pub fn encode(value: ToServer) -> BitArray {
  ffi_encode(value)
}

pub fn decode(bytes: BitArray) -> Result(ToServer, Nil) {
  ffi_decode(bytes)
}

@external(erlang, "to_server_codec_ffi", "ensure")
@external(javascript, "./codec_ffi.mjs", "ensure")
fn ffi_ensure() -> Nil {
  Nil
}

@external(erlang, "to_server_codec_ffi", "encode")
@external(javascript, "./codec_ffi.mjs", "encode_value")
fn ffi_encode(_value: ToServer) -> BitArray {
  bit_array.from_string("")
}

@external(erlang, "to_server_codec_ffi", "decode")
@external(javascript, "./codec_ffi.mjs", "decode_result")
fn ffi_decode(_bytes: BitArray) -> Result(ToServer, Nil) {
  Error(Nil)
}
