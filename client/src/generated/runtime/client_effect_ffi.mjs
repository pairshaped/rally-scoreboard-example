// Generated. Do not edit.
//
// Client effect FFI bridge. Generated transport registers its functions
// here at init time; the generated runtime/effect.gleam module delegates
// to these via @external.
// Derived from the Generator Framework's client effect runtime contract.
// Generated setup_ffi.mjs registers the concrete transport here.

let _transport = null;

export function registerTransport(transport) {
  _transport = transport;
}

export function sendToServer(msg) {
  if (_transport?.sendToServer) _transport.sendToServer(msg);
}

export function hasAuthCookie(name) {
  if (typeof document === "undefined") return false;
  return document.cookie.split(";").some((c) => c.trim().startsWith(name + "="));
}

export function signOut(path) {
  globalThis.location.assign(path);
}

export function setDarkMode(enabled) {
  document.cookie = `scoreboard_dark_mode=${enabled ? "1" : "0"}; path=/; max-age=31536000; SameSite=Lax`;
  document.documentElement.dataset.theme = enabled ? "dark" : "light";
}

export function setLang(lang) {
  document.cookie = `scoreboard_lang=${lang}; path=/; max-age=31536000; SameSite=Lax`;
  document.documentElement.lang = lang;
}

export function readDarkModeCookie() {
  const match = document.cookie.match(/scoreboard_dark_mode=(\d)/);
  if (match) return match[1] === "1";
  return globalThis.matchMedia?.("(prefers-color-scheme: dark)")?.matches ?? false;
}

export function readLangCookie() {
  const match = document.cookie.match(/scoreboard_lang=([^;]+)/);
  return match ? match[1] : "en";
}
