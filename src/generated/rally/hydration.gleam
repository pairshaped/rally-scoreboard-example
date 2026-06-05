@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/client_protocol
@target(javascript)
import generated/rally/result.{type ApiLoadError}
@target(javascript)
import gleam/bit_array
@target(javascript)
import gleam/string

@target(javascript)
pub fn admin_games_load_result() -> Result(
  Result(load_result, List(ApiLoadError)),
  Nil,
) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw ->
      case string.split(raw, ",") {
        [encoded, ..] -> decode_admin_games_load_result(encoded)
        [] -> Error(Nil)
      }
  }
}

@target(javascript)
pub fn public_game_detail_load_result() -> Result(
  Result(load_result, List(ApiLoadError)),
  Nil,
) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw ->
      case string.split(raw, ",") {
        [encoded, ..] -> decode_public_game_detail_load_result(encoded)
        [] -> Error(Nil)
      }
  }
}

@target(javascript)
pub fn public_games_load_result() -> Result(
  Result(load_result, List(ApiLoadError)),
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
  Result(load_result, List(ApiLoadError)),
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
pub fn public_team_detail_load_result() -> Result(
  Result(load_result, List(ApiLoadError)),
  Nil,
) {
  case browser.take_boot_string("hydration") {
    "" -> Error(Nil)
    raw ->
      case string.split(raw, ",") {
        [encoded, ..] -> decode_public_team_detail_load_result(encoded)
        [] -> Error(Nil)
      }
  }
}

@target(javascript)
fn decode_admin_games_load_result(
  encoded: String,
) -> Result(Result(load_result, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case client_protocol.decode_admin_games_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

@target(javascript)
fn decode_public_game_detail_load_result(
  encoded: String,
) -> Result(Result(load_result, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case client_protocol.decode_public_game_detail_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

@target(javascript)
fn decode_public_games_load_result(
  encoded: String,
) -> Result(Result(load_result, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case client_protocol.decode_public_games_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

@target(javascript)
fn decode_public_standings_load_result(
  encoded: String,
) -> Result(Result(load_result, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case client_protocol.decode_public_standings_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}

@target(javascript)
fn decode_public_team_detail_load_result(
  encoded: String,
) -> Result(Result(load_result, List(ApiLoadError)), Nil) {
  case bit_array.base64_url_decode(encoded) {
    Ok(bytes) ->
      case client_protocol.decode_public_team_detail_load_result(bytes) {
        Ok(#(_, result)) -> Ok(result)
        Error(Nil) -> Error(Nil)
      }
    Error(_) -> Error(Nil)
  }
}
