export function path() {
  return globalThis.location?.pathname || "/";
}

export function websocket_url() {
  const location = globalThis.location;
  if (!location) return "ws://localhost:8080/ws";
  const protocol = location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${location.host}/ws`;
}

const DEVICE_COOKIE_NAME = "_scoreboard_device";

export function device_dark_mode() {
  const raw = getCookie(DEVICE_COOKIE_NAME);
  if (raw) {
    const params = new URLSearchParams(raw);
    return params.get("dark_mode") === "1";
  }

  return typeof globalThis.matchMedia === "function"
    ? globalThis.matchMedia("(prefers-color-scheme: dark)").matches
    : false;
}

export function apply_dark_mode(darkMode) {
  const document = globalThis.document;
  if (!document?.documentElement) return;
  document.documentElement.dataset.theme = darkMode ? "dark" : "light";
}

export function persist_dark_mode(darkMode) {
  const value = "v=1&dark_mode=" + (darkMode ? "1" : "0");
  setCookie(DEVICE_COOKIE_NAME, value, 365);
}

function getCookie(name) {
  const document = globalThis.document;
  if (!document?.cookie) return null;
  const escapedName = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = document.cookie.match(new RegExp("(?:^|; )" + escapedName + "=([^;]*)"));
  return match ? decodeURIComponent(match[1]) : null;
}

function setCookie(name, value, days) {
  const document = globalThis.document;
  if (!document) return;
  const expires = days
    ? "; expires=" + new Date(Date.now() + days * 864e5).toUTCString()
    : "";
  document.cookie = name + "=" + value + "; Path=/; SameSite=Lax" + expires;
}
