//// Generated. Do not edit.
////
//// Client-side effect API for page modules. The transport bridge is
//// registered by generated client setup via client_effect_ffi.mjs.
//// Derived from the Generator Framework's client effect runtime contract.
//// Delegates browser effects to client_effect_ffi.mjs.

import lustre/effect

pub type Effect(a) =
  effect.Effect(a)

pub fn send_to_server(msg: a) -> Effect(b) {
  effect.from(fn(_dispatch) {
    let Nil = do_send_to_server(msg)
    Nil
  })
}

pub fn set_dark_mode(enabled: Bool) -> Effect(a) {
  effect.from(fn(_dispatch) {
    let Nil = do_set_dark_mode(enabled)
    Nil
  })
}

pub fn read_dark_mode() -> Bool {
  do_read_dark_mode()
}

@external(javascript, "./client_effect_ffi.mjs", "sendToServer")
fn do_send_to_server(_msg: a) -> Nil {
  Nil
}

@external(javascript, "./client_effect_ffi.mjs", "setDarkMode")
fn do_set_dark_mode(_enabled: Bool) -> Nil {
  Nil
}

@external(javascript, "./client_effect_ffi.mjs", "readDarkModeCookie")
fn do_read_dark_mode() -> Bool {
  False
}
