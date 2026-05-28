//// Scoreboard server entry point.
////
//// Opens the app and system SQLite databases prepared by the migration
//// script, then starts the Mist server through generated runtime routing.

import envoy
import generated/entry
import generated/runtime/db
import generated/runtime/live_updates
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

type ServerStartError {
  AppDatabaseOpenFailed
  SystemDatabaseOpenFailed
  ServerStartFailed
}

pub fn main() -> Nil {
  case server_port() {
    Ok(port) ->
      case start_server(port:) {
        Ok(Nil) -> Nil
        Error(reason) -> io.println_error(server_start_error_message(reason))
      }
    Error(InvalidPort(raw)) ->
      io.println_error(
        "Invalid PORT value: " <> raw <> ". Expected an integer.",
      )
  }
}

fn start_server(port port: Int) -> Result(Nil, ServerStartError) {
  use app_db <- result.try(
    db.open("db/scoreboard.db")
    |> result.replace_error(AppDatabaseOpenFailed),
  )
  use system_conn <- result.try(
    system_db.open("db/system.db")
    |> result.replace_error(SystemDatabaseOpenFailed),
  )
  system.start_with_jobs(path: "db/system.db", handler: fn(_name, _payload) {
    Ok(Nil)
  })
  live_updates.start()
  let server_context = server_context.new(db: app_db, system_db: system_conn)

  io.println("Listening on http://localhost:" <> int.to_string(port))
  use _server <- result.try(
    mist.new(fn(req) { entry.handle_request(req: req, server_context:) })
    |> mist.port(port)
    |> mist.start
    |> result.replace_error(ServerStartFailed),
  )
  process.sleep_forever()
  Ok(Nil)
}

fn server_start_error_message(reason: ServerStartError) -> String {
  case reason {
    AppDatabaseOpenFailed -> "Failed to open db/scoreboard.db"
    SystemDatabaseOpenFailed -> "Failed to open db/system.db"
    ServerStartFailed -> "Failed to start server."
  }
}

fn server_port() -> Result(Int, ServerConfigError) {
  let raw = envoy.get("PORT") |> result.unwrap("8080")
  case int.parse(raw) {
    Ok(port) -> Ok(port)
    Error(_) -> Error(InvalidPort(raw))
  }
}
