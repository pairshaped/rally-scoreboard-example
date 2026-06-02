@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/int

@target(erlang)
const secret_key_base = "SCOREBOARD_SECRET_KEY_BASE"

@target(erlang)
const port = "PORT"

@target(erlang)
pub type SecretKeyError {
  MissingSecret
  InvalidSecretEncoding
  InvalidSecretLength(bytes: Int)
}

@target(erlang)
pub fn secret_key() -> Result(BitArray, SecretKeyError) {
  case getenv(secret_key_base) {
    Error(Nil) -> Error(MissingSecret)
    Ok(encoded) ->
      case bit_array.base64_url_decode(encoded) {
        Error(Nil) -> Error(InvalidSecretEncoding)
        Ok(key) ->
          case bit_array.byte_size(key) {
            32 -> Ok(key)
            bytes -> Error(InvalidSecretLength(bytes))
          }
      }
  }
}

@target(erlang)
pub fn secret_key_error_message(error: SecretKeyError) -> String {
  case error {
    MissingSecret -> secret_key_base <> " is not set"
    InvalidSecretEncoding -> secret_key_base <> " must be valid base64"
    InvalidSecretLength(bytes) ->
      secret_key_base
      <> " must decode to exactly 32 bytes, got "
      <> int.to_string(bytes)
  }
}

@target(erlang)
pub fn http_port(default default: Int) -> Int {
  case getenv(port) {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(Nil) -> default
      }
    Error(Nil) -> default
  }
}

@target(erlang)
@external(erlang, "server_config_ffi", "getenv")
fn getenv(name: String) -> Result(String, Nil)
