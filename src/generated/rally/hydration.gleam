@target(javascript)
import api/to_client.{type ToClient}
@target(javascript)
import generated/libero/client as generated_client
@target(javascript)
import generated/libero/result.{type ApiLoadError}
@target(javascript)
import generated/libero/to_client_codec
@target(javascript)
import generated/rally/browser
@target(javascript)
import gleam/bit_array
@target(javascript)
import gleam/list
@target(javascript)
import gleam/string
@target(javascript)
import public/pages/games/wire as public_games_wire
@target(javascript)
import public/pages/standings/wire as public_standings_wire

@target(javascript)
pub fn messages() -> Result(List(ToClient), Nil) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw -> decode_all(string.split(raw, ","), [])
  }
}

@target(javascript)
pub fn public_games_load_result() -> Result(
  Result(public_games_wire.LoadResult, List(ApiLoadError)),
  Nil,
) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw ->
      case string.split(raw, ",") {
        [encoded, ..] -> decode_public_games_load_result(encoded)
        [] -> Error(Nil)
      }
  }
}

@target(javascript)
pub fn public_standings_load_result() -> Result(
  Result(public_standings_wire.LoadResult, List(ApiLoadError)),
  Nil,
) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw ->
      case string.split(raw, ",") {
        [encoded, ..] -> decode_public_standings_load_result(encoded)
        [] -> Error(Nil)
      }
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

@target(javascript)
fn decode_public_games_load_result(
  encoded: String,
) -> Result(Result(public_games_wire.LoadResult, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case generated_client.decode_public_games_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

@target(javascript)
fn decode_public_standings_load_result(
  encoded: String,
) -> Result(Result(public_standings_wire.LoadResult, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case generated_client.decode_public_standings_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}
