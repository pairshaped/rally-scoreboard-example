@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/int

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
const secret_key_base = "SCOREBOARD_SECRET_KEY_BASE"

@target(erlang)
const port = "PORT"

@target(erlang)
/// Configuration error returned by secret_key.
/// scoreboard_unified turns this into startup output before refusing to run with
/// an invalid session encryption key.
pub type SecretKeyError {
  MissingSecret
  InvalidSecretEncoding
  InvalidSecretLength(bytes: Int)
}

@target(erlang)
/// Reads the session encryption key from process configuration.
/// scoreboard_unified calls this on startup before constructing Rally auth state.
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
/// Formats secret_key errors for startup logs.
/// scoreboard_unified uses this before refusing to run with an invalid key.
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
/// Reads the HTTP port from process configuration.
/// scoreboard_unified calls this when starting rally/runtime/http_server.
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
@external(erlang, "app_config_ffi", "getenv")
fn getenv(name: String) -> Result(String, Nil)
