import authentication_context
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn normalize_email_test() {
  authentication_context.normalize_email(" Admin@Example.COM ")
  |> should.equal("admin@example.com")
}

pub fn normalize_display_name_test() {
  authentication_context.normalize_display_name(" Fan ")
  |> should.equal(Some("Fan"))

  authentication_context.normalize_display_name(" ")
  |> should.equal(None)
}
