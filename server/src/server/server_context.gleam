//// Per-server request context shared by handlers.
////
//// Rally passes this through generated runtimes so page handlers can use app
//// and system database connections without importing server boot code.

import sqlight

pub type ServerContext {
  ServerContext(db: sqlight.Connection, system_db: sqlight.Connection)
}

pub fn new(
  db db: sqlight.Connection,
  system_db system_db: sqlight.Connection,
) -> ServerContext {
  ServerContext(db:, system_db:)
}
