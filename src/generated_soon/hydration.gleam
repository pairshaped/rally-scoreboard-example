@target(javascript)
import api/to_client.{type ToClient}
@target(javascript)
import generated/api/to_client_codec
@target(javascript)
import generated_soon/browser
@target(javascript)
import gleam/bit_array
@target(javascript)
import gleam/list
@target(javascript)
import gleam/string

@target(javascript)
pub fn messages() -> Result(List(ToClient), Nil) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw -> decode_all(string.split(raw, ","), [])
  }
}

@target(javascript)
fn decode_all(
  encoded: List(String),
  decoded: List(ToClient),
) -> Result(List(ToClient), Nil) {
  case encoded {
    [] -> Ok(list.reverse(decoded))
    [first, ..rest] ->
      case decode_message(first) {
        Ok(message) -> decode_all(rest, [message, ..decoded])
        Error(Nil) -> Error(Nil)
      }
  }
}

@target(javascript)
fn decode_message(encoded: String) -> Result(ToClient, Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) -> to_client_codec.decode(bytes)
    Error(_) -> Error(Nil)
  }
}
