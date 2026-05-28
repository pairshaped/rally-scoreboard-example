//// Generated. Do not edit.
////
//// Gleam entry point for the generated JavaScript setup bridge.
//// Call this once before starting the Lustre application.
//// Derived from the Generator Framework's client setup runtime contract.
//// Delegates to client/src/generated/setup_ffi.mjs.

import gleam/option.{type Option}

@external(javascript, "./setup_ffi.mjs", "setup")
pub fn setup() -> Nil {
  Nil
}

@external(javascript, "./setup_ffi.mjs", "readSsrToClient")
pub fn read_ssr_to_client() -> Option(a) {
  option.None
}

@external(javascript, "./setup_ffi.mjs", "readClientSharedState")
pub fn read_client_shared_state() -> Option(a) {
  option.None
}
