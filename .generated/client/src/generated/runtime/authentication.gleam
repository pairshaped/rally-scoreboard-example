//// Generated. Do not edit.
////
//// Client-side authentication effects.
//// Derived from the Generator Framework's client authentication runtime contract.
//// Emits sign-out navigation that app clients can attach to authenticated UI.

import lustre/effect.{type Effect}

// nolint: unused_exports -- part of the generated runtime API contract; available for app-owned sign-out UI but not yet wired in Scoreboard.
pub fn sign_out(path path: String) -> Effect(msg) {
  effect.from(fn(_dispatch) {
    let Nil = do_sign_out(path)
    Nil
  })
}

@external(javascript, "./client_effect_ffi.mjs", "signOut")
fn do_sign_out(_path: String) -> Nil {
  Nil
}
