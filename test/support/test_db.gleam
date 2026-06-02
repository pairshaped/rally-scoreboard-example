@target(erlang)
import gleam/result
@target(erlang)
import marmot.{type ResetError}
@target(erlang)
import sqlight.{type Connection}

@target(erlang)
pub type SetupError {
  ResetFailed(reason: ResetError)
  OpenFailed
}

@target(erlang)
pub fn setup(name name: String) -> Result(Connection, SetupError) {
  let path = "/tmp/scoreboard-unified-" <> name <> ".db"

  case marmot.reset(path) {
    Ok(_) ->
      sqlight.open(path)
      |> result.map_error(fn(_) { OpenFailed })
    Error(error) -> Error(ResetFailed(error))
  }
}
