//// Authentication tests for the admin Mount.
////
//// Exercises the DB-backed auth module's sign-in code verification, cookie
//// issuance, and token verification paths.

import generated/runtime/authentication as auth_runtime
import generated/runtime/db
import gleam/option
import gleeunit
import gleeunit/should
import server/admin/authentication
import sqlight

fn test_db() -> sqlight.Connection {
  let assert Ok(conn) = db.open(":memory:")
  let assert Ok(Nil) =
    sqlight.exec(
      "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        display_name TEXT,
        sign_in_code_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'fan' CHECK (role IN ('admin', 'fan')),
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )",
      on: conn,
    )
  let assert Ok(Nil) =
    sqlight.exec(
      "INSERT OR IGNORE INTO users (email, display_name, sign_in_code_hash, role) VALUES "
        <> "('admin@example.com', NULL, '$runtime-sign-in-code-hmac-sha256$v=1$FY-UwgWkAUbUUAjKZIrySIhmkDwEniQHxhEw7QwbcGU', 'admin'),"
        <> "('fan@example.com', 'Fan', '$runtime-sign-in-code-hmac-sha256$v=1$26QkhMJZyJsBDiH3ae0NfkdhN2ynV41mmuBmMphzqB8', 'fan')",
      on: conn,
    )
  conn
}

pub fn main() {
  gleeunit.main()
}

pub fn verify_sign_in_code_accepts_correct_code_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "admin@example.com",
    code: "A1Z9Q",
  )
  |> should.not_equal(option.None)
}

pub fn verify_sign_in_code_rejects_wrong_code_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "admin@example.com",
    code: "WRONG",
  )
  |> should.equal(option.None)
}

pub fn sign_in_code_normalizes_case_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "admin@example.com",
    code: "a1z9q",
  )
  |> should.not_equal(option.None)
}

pub fn fan_can_sign_in_with_code_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "fan@example.com",
    code: "A1Z9Q",
  )
  |> should.not_equal(option.None)
}

pub fn fan_user_id_is_returned_on_sign_in_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "fan@example.com",
    code: "A1Z9Q",
  )
  |> should.equal(option.Some(2))
}

pub fn admin_user_id_is_returned_on_sign_in_test() {
  let conn = test_db()
  authentication.verify_sign_in_code(
    db: conn,
    email: "admin@example.com",
    code: "A1Z9Q",
  )
  |> should.equal(option.Some(1))
}

pub fn issued_cookie_is_authenticated_test() {
  let session_id = "test-session-abc"
  let cookie = authentication.issue_cookie(session_id:, user_id: 1)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.is_authenticated(cookie_header: Ok(header), session_id:)
  |> should.be_true
}

pub fn is_authenticated_rejects_wrong_session_test() {
  let session_id = "test-session-abc"
  let cookie = authentication.issue_cookie(session_id:, user_id: 1)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.is_authenticated(
    cookie_header: Ok(header),
    session_id: "different-session",
  )
  |> should.be_false
}

pub fn is_authenticated_rejects_missing_cookie_test() {
  authentication.is_authenticated(
    cookie_header: Error(Nil),
    session_id: "test-session-abc",
  )
  |> should.be_false
}

pub fn authenticated_user_id_returns_some_for_valid_token_test() {
  let session_id = "test-session-user"
  let cookie = authentication.issue_cookie(session_id:, user_id: 1)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.authenticated_user_id(Ok(header), session_id)
  |> should.not_equal(option.None)
}

pub fn authenticated_user_id_returns_none_for_invalid_session_test() {
  let session_id = "test-session-bad"
  let cookie = authentication.issue_cookie(session_id:, user_id: 1)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.authenticated_user_id(Ok(header), "wrong-session")
  |> should.equal(option.None)
}
