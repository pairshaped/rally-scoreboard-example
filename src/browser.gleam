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
@external(javascript, "./browser_ffi.mjs", "boot_auth_user_id")
pub fn boot_auth_user_id() -> Int {
  0
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_auth_email")
pub fn boot_auth_email() -> String {
  ""
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_auth_display_name")
pub fn boot_auth_display_name() -> String {
  ""
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_can_access_admin")
pub fn boot_can_access_admin() -> Bool {
  False
}

@target(javascript)
@external(javascript, "./browser_ffi.mjs", "boot_hydration")
pub fn boot_hydration() -> String {
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
