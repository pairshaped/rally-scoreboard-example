@target(erlang)
pub fn ensure() -> Nil {
  Nil
}

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

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_int")
pub fn boot_int(_name: String, _fallback: Int) -> Int {
  0
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_string")
pub fn boot_string(_name: String) -> String {
  ""
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_bool")
pub fn boot_bool(_name: String) -> Bool {
  False
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "take_boot_string")
pub fn take_boot_string(_name: String) -> String {
  ""
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "query_string")
pub fn query_string() -> String {
  ""
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "push_path")
pub fn push_path(_path: String) -> Nil {
  Nil
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "listen_popstate")
pub fn listen_popstate(_dispatch: fn(String) -> Nil) -> Nil {
  Nil
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "listen_spa_navigation")
pub fn listen_spa_navigation(_dispatch: fn(String) -> Nil) -> Nil {
  Nil
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "device_dark_mode")
pub fn device_dark_mode() -> Bool {
  False
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "apply_dark_mode")
pub fn apply_dark_mode(_dark_mode: Bool) -> Nil {
  Nil
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "persist_dark_mode")
pub fn persist_dark_mode(_dark_mode: Bool) -> Nil {
  Nil
}
