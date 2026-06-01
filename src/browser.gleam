@target(javascript)
@external(javascript, "./browser_ffi.mjs", "path")
pub fn path() -> String {
  "/"
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "websocket_url")
pub fn websocket_url() -> String {
  "ws://localhost:8080/ws"
}
