//// Authentication tests for the admin Mount.
////
//// Exercises the demo auth module's password verification, sign-in code
//// verification, cookie issuance, and token verification paths.

import generated/runtime/authentication as auth_runtime
import gleam/option
import gleeunit
import gleeunit/should
import server/admin/authentication

pub fn main() {
  gleeunit.main()
}

pub fn verify_password_accepts_correct_credentials_test() {
  authentication.verify_password(email: "admin@example.com", password: "admin")
  |> should.be_true
}

pub fn verify_password_rejects_wrong_password_test() {
  authentication.verify_password(email: "admin@example.com", password: "wrong")
  |> should.be_false
}

pub fn verify_password_rejects_wrong_email_test() {
  authentication.verify_password(email: "other@example.com", password: "admin")
  |> should.be_false
}

pub fn verify_password_normalizes_email_test() {
  authentication.verify_password(
    email: "  Admin@Example.COM  ",
    password: "admin",
  )
  |> should.be_true
}

pub fn verify_sign_in_code_accepts_correct_code_test() {
  authentication.verify_sign_in_code(email: "admin@example.com", code: "A1Z9Q")
  |> should.be_true
}

pub fn verify_sign_in_code_rejects_wrong_code_test() {
  authentication.verify_sign_in_code(email: "admin@example.com", code: "WRONG")
  |> should.be_false
}

pub fn sign_in_code_normalizes_case_test() {
  authentication.verify_sign_in_code(email: "admin@example.com", code: "a1z9q")
  |> should.be_true
}

pub fn issued_cookie_is_authenticated_test() {
  let session_id = "test-session-abc"
  let cookie = authentication.issue_cookie(session_id:)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.is_authenticated(cookie_header: Ok(header), session_id:)
  |> should.be_true
}

pub fn is_authenticated_rejects_wrong_session_test() {
  let session_id = "test-session-abc"
  let cookie = authentication.issue_cookie(session_id:)
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
  let cookie = authentication.issue_cookie(session_id:)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.authenticated_user_id(Ok(header), session_id)
  |> should.not_equal(option.None)
}

pub fn authenticated_user_id_returns_none_for_invalid_session_test() {
  let session_id = "test-session-bad"
  let cookie = authentication.issue_cookie(session_id:)
  let assert auth_runtime.SetCookie(name:, value:, max_age: _) = cookie
  let header = name <> "=" <> value
  authentication.authenticated_user_id(Ok(header), "wrong-session")
  |> should.equal(option.None)
}
