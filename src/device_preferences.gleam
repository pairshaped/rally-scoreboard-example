import gleam/list
import gleam/result
import gleam/string

pub const cookie_name = "_scoreboard_device"

/// Browser/device preference cookie payload.
/// app_document reads this on SSR, and browser mount code keeps the dark-mode
/// shell state aligned with the same shape.
pub type DevicePreferences {
  DevicePreferences(dark_mode: Bool)
}

/// Default cookie state used when SSR cannot parse device preferences.
/// app_document falls back to this before rendering the shell.
pub fn default() -> DevicePreferences {
  DevicePreferences(dark_mode: False)
}

/// Encodes device preferences for the browser cookie.
/// browser_mount writes this through generated Rally browser helpers.
pub fn encode(preferences: DevicePreferences) -> String {
  "v=1&dark_mode=" <> bool_flag(preferences.dark_mode)
}

/// Parses the device preference cookie read during SSR.
/// app_document uses this to choose the initial shell theme before hydration.
pub fn parse(value: String) -> Result(DevicePreferences, Nil) {
  use pairs <- result.try(parse_query(value))
  use _ <- result.try(require_version(pairs))
  use #(_, dark_mode) <- result.try(
    list.find_map(pairs, fn(pair) {
      case pair.0 {
        "dark_mode" -> Ok(pair)
        _ -> Error(Nil)
      }
    }),
  )

  case dark_mode {
    "1" -> Ok(DevicePreferences(dark_mode: True))
    "0" -> Ok(DevicePreferences(dark_mode: False))
    _ -> Error(Nil)
  }
}

fn parse_query(query: String) -> Result(List(#(String, String)), Nil) {
  case query {
    "" -> Ok([])
    _ ->
      query
      |> string.split("&")
      |> list.map(fn(pair) {
        case string.split(pair, "=") {
          [key, value] -> Ok(#(key, value))
          _ -> Error(Nil)
        }
      })
      |> result.all
  }
}

fn require_version(pairs: List(#(String, String))) -> Result(Nil, Nil) {
  case list.key_find(pairs, "v") {
    Ok("1") -> Ok(Nil)
    _ -> Error(Nil)
  }
}

fn bool_flag(value: Bool) -> String {
  case value {
    True -> "1"
    False -> "0"
  }
}
