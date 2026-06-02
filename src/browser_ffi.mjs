export function path() {
  return globalThis.location?.pathname || "/";
}

export function websocket_url() {
  const location = globalThis.location;
  if (!location) return "ws://localhost:8080/ws";
  const protocol = location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${location.host}/ws`;
}

function bootData() {
  return globalThis.document?.querySelector?.("#app")?.dataset ?? {};
}

export function boot_auth_user_id() {
  const value = Number.parseInt(bootData().authUserId ?? "0", 10);
  return Number.isFinite(value) ? value : 0;
}

export function boot_auth_email() {
  return bootData().authEmail ?? "";
}

export function boot_auth_display_name() {
  return bootData().authDisplayName ?? "";
}

export function boot_can_access_admin() {
  return bootData().canAccessAdmin === "1";
}

export function boot_hydration() {
  const data = bootData();
  const value = data.hydration ?? "";
  delete data.hydration;
  return value;
}

export function query_string() {
  const search = globalThis.location?.search ?? "";
  const params = new URLSearchParams(search);
  return Array.from(params.entries())
    .map(([key, value]) => `${key}=${value}`)
    .join("&");
}

export function push_path(path) {
  const history = globalThis.history;
  const location = globalThis.location;
  if (!history || !location || location.pathname === path) return;
  history.pushState(null, "", path);
}

export function listen_popstate(dispatch) {
  globalThis.addEventListener?.("popstate", () => {
    dispatch(path());
  });
}

export function listen_spa_navigation(dispatch) {
  globalThis.document?.addEventListener?.("click", event => {
    if (event.defaultPrevented || event.button !== 0) return;
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

    const link = event.target?.closest?.("a[data-scoreboard-spa-nav]");
    if (!link) return;

    const location = globalThis.location;
    if (!location) return;

    const url = new URL(link.href, location.href);
    if (url.origin !== location.origin) return;

    const destination = url.pathname + url.search;
    if (destination === location.pathname + location.search) {
      event.preventDefault();
      return;
    }

    event.preventDefault();
    dispatch(destination);
  });
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
