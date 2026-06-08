@target(erlang)
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/client_transport
@target(javascript)
import gleam/result
@target(javascript)
import gleam/uri
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import rally/runtime/browser_navigation

@target(javascript)
pub fn device_dark_mode() -> Bool {
  browser.device_dark_mode()
}

@target(javascript)
fn apply_dark_mode(dark_mode: Bool) -> Effect(msg) {
  effect.from(fn(_dispatch) { browser.apply_dark_mode(dark_mode) })
}

@target(javascript)
fn persist_dark_mode(dark_mode: Bool) -> Effect(msg) {
  effect.from(fn(_dispatch) { browser.persist_dark_mode(dark_mode) })
}

@target(javascript)
pub fn dark_mode_changed_effects(dark_mode dark_mode: Bool) -> Effect(msg) {
  effect.batch([
    persist_dark_mode(dark_mode),
    apply_dark_mode(dark_mode),
  ])
}

@target(javascript)
pub fn startup_effects(
  dark_mode dark_mode: Bool,
  on_frame on_frame: fn(BitArray) -> msg,
  on_shell_navigation on_shell_navigation: fn(String) -> msg,
  on_browser_navigation on_browser_navigation: fn(String) -> msg,
) -> Effect(msg) {
  effect.batch([
    apply_dark_mode(dark_mode),
    client_transport.connect(url: browser.websocket_url(), on_frame: on_frame),
    listen_for_shell_navigation(on_shell_navigation),
    listen_for_browser_navigation(on_browser_navigation),
  ])
}

@target(javascript)
pub fn push_path(path: String) -> Effect(msg) {
  browser_navigation.push_path(path)
}

@target(javascript)
fn listen_for_browser_navigation(to_message: fn(String) -> msg) -> Effect(msg) {
  browser_navigation.listen_browser_navigation(to_message)
}

@target(javascript)
fn listen_for_shell_navigation(to_message: fn(String) -> msg) -> Effect(msg) {
  browser_navigation.listen_shell_navigation(to_message)
}

@target(javascript)
pub fn query_pairs() -> List(#(String, String)) {
  browser.query_string()
  |> parse_query_pairs
}

@target(javascript)
pub fn query_pairs_for_path(path path: String) -> List(#(String, String)) {
  browser.query_string_for_path(path)
  |> parse_query_pairs
}

@target(javascript)
fn parse_query_pairs(query query: String) -> List(#(String, String)) {
  uri.parse_query(query)
  |> result.unwrap([])
}
