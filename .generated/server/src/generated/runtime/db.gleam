//// Generated. Do not edit.
////
//// Server database helpers.
//// Derived from the Generator Framework's server database runtime contract.
//// Emits SQLite helpers used by handwritten server pages and generated SSR/runtime code.

import generated/runtime/env
import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import logging
import sqlight

/// Open a SQLite connection with the Generator Framework's default pragmas:
/// WAL, busy timeout, and foreign key enforcement.
pub fn open(path: String) -> Result(sqlight.Connection, sqlight.Error) {
  use conn <- result.try(sqlight.open(path))
  use _ <- result.try(sqlight.exec("PRAGMA journal_mode=WAL;", on: conn))
  use _ <- result.try(sqlight.exec("PRAGMA busy_timeout=5000;", on: conn))
  use _ <- result.try(sqlight.exec("PRAGMA foreign_keys=ON;", on: conn))
  Ok(conn)
}

/// Return the only row in a result set, or None when the query returned
/// zero rows or more than one row.
pub fn one(rows: List(a)) -> Option(a) {
  case rows {
    [row] -> Some(row)
    _ -> None
  }
}

/// Encode a Bool as a SQLite integer value, using 1 for True and 0 for False.
pub fn bool_to_int(val: Bool) -> sqlight.Value {
  sqlight.int(case val {
    True -> 1
    False -> 0
  })
}

/// Encode optional text as a SQLite value.
pub fn nullable_text(val: Option(String)) -> sqlight.Value {
  case val {
    Some(s) -> sqlight.text(s)
    None -> sqlight.null()
  }
}

/// Timed query wrapper. Same signature as sqlight.query but logs query text,
/// param count, elapsed time, and row count in dev mode.
pub fn query(
  sql sql: String,
  on conn: sqlight.Connection,
  with params: List(sqlight.Value),
  expecting decoder: decode.Decoder(a),
) -> Result(List(a), sqlight.Error) {
  let start = timestamp.system_time()
  let result = sqlight.query(sql, on: conn, with: params, expecting: decoder)
  let elapsed_ms =
    timestamp.difference(start, timestamp.system_time())
    |> duration.to_milliseconds()
  log_query(sql: sql, param_count: list.length(params), elapsed_ms: elapsed_ms)
  log_result(result)
  result
}

/// Run a nested-safe SQLite transaction using SAVEPOINT.
pub fn transaction(
  conn: sqlight.Connection,
  body: fn() -> Result(a, sqlight.Error),
) -> Result(a, sqlight.Error) {
  let id = int.absolute_value(unique_id())
  let savepoint = "sp_" <> int.to_string(id)
  use _ <- result.try(sqlight.exec("SAVEPOINT " <> savepoint <> ";", on: conn))
  case body() {
    Ok(val) -> {
      use _ <- result.try(sqlight.exec("RELEASE " <> savepoint <> ";", on: conn))
      Ok(val)
    }
    Error(err) -> {
      let _rollback = sqlight.exec("ROLLBACK TO " <> savepoint <> ";", on: conn)
      use _ <- result.try(sqlight.exec("RELEASE " <> savepoint <> ";", on: conn))
      Error(err)
    }
  }
}

fn log_query(
  sql sql: String,
  param_count param_count: Int,
  elapsed_ms elapsed_ms: Int,
) -> Nil {
  use <- bool.guard(when: !env.is_dev(), return: Nil)
  let msg =
    collapse_whitespace(sql)
    <> " | params: "
    <> int.to_string(param_count)
    <> " ("
    <> int.to_string(elapsed_ms)
    <> "ms)"
  logging.log(logging.Debug, msg)
}

fn log_result(result: Result(List(a), sqlight.Error)) -> Nil {
  use <- bool.guard(when: !env.is_dev(), return: Nil)
  case result {
    Ok(rows) ->
      logging.log(
        logging.Debug,
        "-> " <> int.to_string(list.length(rows)) <> " row(s)",
      )
    Error(err) -> logging.log(logging.Warning, "-> DB ERROR: " <> err.message)
  }
}

fn collapse_whitespace(sql: String) -> String {
  sql
  |> string.replace("\n", " ")
  |> string.replace("\t", " ")
  |> string.split(on: " ")
  |> list.filter(fn(part) { part != "" })
  |> string.join(with: " ")
  |> string.trim()
}

@external(erlang, "erlang", "unique_integer")
fn unique_id() -> Int
