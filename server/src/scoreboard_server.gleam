//// Scoreboard server entry point.
////
//// Opens the app and system SQLite databases prepared by the migration
//// script, then starts the Mist server through generated runtime routing.

import envoy
import generated/entry
import generated/runtime/db
import generated/runtime/system
import generated/runtime/system_db
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/result
import mist
import server/server_context

type ServerConfigError {
  InvalidPort(String)
}

pub fn main() -> Nil {
  let assert Ok(db) = db.open("db/scoreboard.db")
  let assert Ok(system_conn) = system_db.open("db/system.db")
  system.start_with_jobs(path: "db/system.db", handler: fn(_name, _payload) {
    Ok(Nil)
  })
  let server_context = server_context.new(db:, system_db: system_conn)
  let assert Ok(port) = server_port()

  io.println("Listening on http://localhost:" <> int.to_string(port))
  let assert Ok(_) =
    mist.new(fn(req) { entry.handle_request(req: req, server_context:) })
    |> mist.port(port)
    |> mist.start
  process.sleep_forever()
}

fn server_port() -> Result(Int, ServerConfigError) {
  let raw = envoy.get("PORT") |> result.unwrap("8080")
  case int.parse(raw) {
    Ok(port) -> Ok(port)
    Error(_) -> Error(InvalidPort(raw))
  }
}
