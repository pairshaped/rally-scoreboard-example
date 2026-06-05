@target(javascript)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_mount as rally_browser_mount
@target(javascript)
import gleam/option.{type Option, None, Some}

@target(erlang)
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
/// Reads the authenticated identity embedded in the SSR boot payload.
/// public_app and admin_app call this while constructing their shared shell
/// state.
pub fn boot_authentication_context() -> Option(AuthenticationContext) {
  case browser.boot_int("authUserId", 0) {
    0 -> None
    user_id -> {
      let display_name = case browser.boot_string("authDisplayName") {
        "" -> None
        value -> Some(value)
      }
      Some(AuthenticationContext(
        user_id:,
        email: browser.boot_string("authEmail"),
        display_name:,
      ))
    }
  }
}

@target(javascript)
/// Reads browser query params for page init.
/// public_app passes these into generated Proute/Rally page loading.
pub fn query_pairs() -> List(#(String, String)) {
  rally_browser_mount.query_pairs()
}
