//// Database helper functions shared by server handlers.
////
//// Helpers live here only when multiple page handler modules need the same
//// behavior.

import sqlight

pub type QueryError {
  DatabaseError(String)
  NotFound(String)
  UnexpectedRows(String)
  ValidationError(String)
}

pub fn from_sqlight(err: sqlight.Error) -> QueryError {
  DatabaseError(error(err))
}

pub fn not_found(message message: String) -> QueryError {
  NotFound(message)
}

pub fn unexpected_rows(message message: String) -> QueryError {
  UnexpectedRows(message)
}

pub fn validation(message message: String) -> QueryError {
  ValidationError(message)
}

pub fn to_string(error error: QueryError) -> String {
  case error {
    DatabaseError(message) -> message
    NotFound(message) -> message
    UnexpectedRows(message) -> message
    ValidationError(message) -> message
  }
}

fn error(err: sqlight.Error) -> String {
  "database error: " <> err.message
}
