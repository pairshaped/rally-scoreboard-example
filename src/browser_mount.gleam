@target(javascript)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(javascript)
import device_preferences
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_mount as rally_browser_mount
@target(javascript)
import gleam/option.{type Option, None, Some}
@target(javascript)
import lustre/effect.{type Effect}

@target(javascript)
pub fn device_dark_mode() -> Bool {
  rally_browser_mount.device_dark_mode(device_preferences.cookie_name)
}

@target(javascript)
pub fn dark_mode_changed_effects(dark_mode: Bool) -> Effect(msg) {
  rally_browser_mount.dark_mode_changed_effects(
    cookie_name: device_preferences.cookie_name,
    dark_mode:,
  )
}

@target(javascript)
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
pub fn query_pairs() -> List(#(String, String)) {
  rally_browser_mount.query_pairs()
}
