// Generated. Do not edit.
//
// Browser router FFI. Used by generated router.gleam modules to read
// the current URL before parsing it into the shared Route type.
// Derived from the Generator Framework's client router runtime contract.
// Generated router.gleam modules call this to parse the browser URL.

export function currentUrl() {
  return globalThis.location?.href ?? "http://localhost/";
}
