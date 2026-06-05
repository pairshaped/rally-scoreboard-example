@target(erlang)
import gleam/int

@target(javascript)
pub fn ensure() -> Nil {
  Nil
}

@target(erlang)
const port = "PORT"

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
