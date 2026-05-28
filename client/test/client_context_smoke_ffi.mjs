// Test FFI for client context decode smoke test.
// Sets up the window global that setup_ffi.mjs reads from during SSR boot
// so the decode path can be tested in Node.js.

export function setWindowContext(base64) {
  globalThis.window = { __RUNTIME_CLIENT_CONTEXT__: base64 };
}

export function clearWindowContext() {
  delete globalThis.window;
}
