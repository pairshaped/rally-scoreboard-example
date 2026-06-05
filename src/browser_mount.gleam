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
/// Reads the initial device theme for browser app init.
/// public_app and admin_app call this before generated Rally startup effects
/// subscribe to browser changes.
pub fn device_dark_mode() -> Bool {
  rally_browser_mount.device_dark_mode(device_preferences.cookie_name)
}

@target(javascript)
/// Browser effects for a dark-mode toggle.
/// public_app and admin_app call this after shell messages update shared state.
pub fn dark_mode_changed_effects(dark_mode: Bool) -> Effect(msg) {
  rally_browser_mount.dark_mode_changed_effects(
    cookie_name: device_preferences.cookie_name,
    dark_mode:,
  )
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
