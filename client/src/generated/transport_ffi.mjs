// Generated. Do not edit.
//
// @ts-check
//
// Runtime WebSocket transport layer.
//
// Derived from the Generator Framework's client transport template. It imports encode/decode
// from the generated protocol_wire.mjs facade and handles the WebSocket connection lifecycle,
// reconnects, ToClient push handlers, page-init acknowledgements, SSR flags,
// and debug logging.

import { Error as ResultError, CustomType, Empty, NonEmpty, BitArray } from "../../gleam_stdlib/gleam.mjs";
import { encode_request, decode_server_frame } from "./protocol_wire.mjs";

// ---------- Debug logging ----------

function debugEnabled() {
  if (typeof window === "undefined") return false;
  return window.__RALLY_DEBUG__ === true
      || window.__APP_ENV__ === "dev";
}

function formatRaw(value, depth = 0) {
  if (value === undefined || value === null) return "Nil";
  if (typeof value === "boolean") return value ? "True" : "False";
  if (typeof value === "string") return JSON.stringify(value);
  if (typeof value === "number" || typeof value === "bigint") return String(value);
  if (value instanceof BitArray) return `<<${value.rawBuffer.length} bytes>>`;
  if (value && value.__liberoRawBinary) return `<<${value.rawBuffer.length} bytes>>`;
  if (Array.isArray(value)) {
    if (value.length === 0) return "[]";
    if (typeof value[0] === "string" && /^[a-z_]/.test(value[0])) {
      const tag = pascalCase(value[0]);
      if (value.length === 1) return tag;
      const fields = value.slice(1).map(v => formatRaw(v, depth + 1));
      return `${tag}(${fields.join(", ")})`;
    }
    const items = value.map(v => formatRaw(v, depth + 1));
    return `#(${items.join(", ")})`;
  }
  if (value instanceof Empty) return "[]";
  if (value instanceof NonEmpty) {
    const items = gleamListToArray(value).map(v => formatRaw(v, depth + 1));
    return `[${items.join(", ")}]`;
  }
  if (value instanceof Map) {
    const pairs = [...value.entries()].map(([k, v]) => `${formatRaw(k)}: ${formatRaw(v, depth + 1)}`);
    return `dict.from_list([${pairs.join(", ")}])`;
  }
  if (value instanceof CustomType) {
    const name = value.constructor.name;
    const keys = Object.keys(value);
    if (keys.length === 0) return name;
    const fields = keys.map(k => formatRaw(value[k], depth + 1));
    return `${name}(${fields.join(", ")})`;
  }
  return String(value);
}

function gleamListToArray(list) {
  const out = [];
  let node = list;
  while (node instanceof NonEmpty) {
    out.push(node.head);
    node = node.tail;
  }
  return out;
}

function pascalCase(snake) {
  return snake.split("_").map(s => s.charAt(0).toUpperCase() + s.slice(1)).join("");
}

function recordMessage(direction, label, data, extra) {
  if (typeof window === "undefined") return;
  if (!window.__RALLY_MESSAGES__) window.__RALLY_MESSAGES__ = [];
  const entry = {
    t: performance.now(),
    ts: new Date().toISOString(),
    dir: direction,
    label,
    data,
    formatted: formatRaw(data),
  };
  if (extra) entry.extra = extra;
  window.__RALLY_MESSAGES__.push(entry);
  if (window.__RALLY_MESSAGES__.length > 1000) {
    window.__RALLY_MESSAGES__ = window.__RALLY_MESSAGES__.slice(-500);
  }
}

function logFrame(direction, label, data, extra) {
  if (!debugEnabled()) return;
  recordMessage(direction, label, data, extra);
  const colors = {
    "->": "color: #e8a033; font-weight: bold",
    "<-": "color: #33bbe8; font-weight: bold",
    "<<": "color: #b833e8; font-weight: bold",
  };
  const arrow = direction;
  const style = colors[arrow] || "";
  const parts = [`%c${arrow} ${label}`, style];
  console.groupCollapsed(...parts);
  console.log(formatRaw(data));
  if (extra) {
    for (const [k, v] of Object.entries(extra)) {
      console.log(`${k}:`, v);
    }
  }
  console.groupEnd();
}

if (typeof window !== "undefined") {
  window.__RALLY_FORMAT__ = formatRaw;
}

// ---------- WebSocket ----------
//
// `send` opens the WebSocket lazily on first call and caches the
// connection. Sends issued before the socket's open event are queued
// and flushed once it opens.
//
// Server-to-client frames are decoded through Libero's boundary API.
// decode_server_frame returns `{ kind: "push", module, value }` for
// server ToClient emissions and `{ kind: "response", requestId, value }`
// for page-init acknowledgements. The runtime never inspects tag bytes or slices
// frame headers: Libero owns that boundary.
//
// Reconnection is automatic. On unexpected close (network blip, server
// restart, page resume from sleep), the socket reconnects with exponential
// backoff. Pending commands stay queued until the socket opens. Push
// handlers remain registered across reconnects, so push frames resume once
// the socket is back. Apps that need to refetch state on reconnect should
// register an `on_connect` listener (see registerOnConnect below).

let ws = null;
let pendingSends = [];    // ArrayBuffer payloads waiting for an open socket
let nextRequestId = 1;

// Push handler registry: module path to callback.
const pushHandlers = new Map();

// Connection lifecycle listeners. `on_connect` fires on every socket
// open; first connect AND reconnects; so apps can use one path for
// "load initial state". `on_disconnect` fires when the socket closes
// (the reason string is human-readable and intended for UX).
const onConnectListeners = new Set();
const onDisconnectListeners = new Set();

// Reconnect state. lastUrl is captured on first ensureSocket() so
// auto-reconnect can re-create the socket without the caller passing
// the URL again.
let lastUrl = null;
let reconnectTimer = null;
let reconnectAttempts = 0;
const RECONNECT_BASE_MS = 500;
const RECONNECT_MAX_MS = 30_000;

function toWebSocketPayload(payload) {
  if (payload && payload.rawBuffer instanceof Uint8Array) {
    return payload.rawBuffer;
  }
  return payload;
}

/**
 * Pure detection of authentication protocol error strings from the server.
 *
 * The server sends Error("authentication:redirect:<url>") when a Required page
 * blocks unauthenticated access, and Error("authentication:forbidden") when
 * authorization check fails.
 *
 * Unknown authentication:* values, non-string errors, and non-Error values
 * return null and fall through to the existing response path.
 *
 * @param {any} value - decoded frame value
 * @returns {{ kind: "redirect", url: string } | { kind: "forbidden" } | null}
 */
export function detectAuthenticationError(value) {
  if (!(value instanceof ResultError)) return null;
  const errValue = value[0];
  if (typeof errValue !== "string") return null;

  if (errValue.startsWith("authentication:redirect:")) {
    return { kind: "redirect", url: errValue.slice("authentication:redirect:".length) };
  }
  if (errValue === "authentication:forbidden") {
    return { kind: "forbidden" };
  }
  return null;
}

/**
 * Handle authentication protocol errors from the server with side effects.
 *
 * Page-init acknowledgements are the only response frames expected by
 * the root API transport, so this is where authentication failures are caught.
 *
 * @param {{ kind: string, requestId: number, value: any }} frame
 * @returns {boolean} true if the frame was handled as an authentication error
 */
function handleAuthenticationError(frame) {
  const detected = detectAuthenticationError(frame.value);
  if (!detected) return false;

  if (detected.kind === "redirect") {
    if (typeof window !== "undefined" && window.location) {
      window.location.href = detected.url;
    }
    return true;
  }

  if (debugEnabled()) console.error("[runtime] Authentication error: authentication:forbidden");
  return true;
}

function clearPending() {
  pendingSends = [];
}

// Compute the next reconnect delay with full jitter: pick a value in
// [cap/2, cap] where cap doubles each attempt. The jitter avoids a
// thundering herd if many clients drop and reconnect together.
function nextReconnectDelay() {
  const cap = Math.min(
    RECONNECT_BASE_MS * Math.pow(2, reconnectAttempts),
    RECONNECT_MAX_MS,
  );
  return cap / 2 + Math.random() * (cap / 2);
}

function scheduleReconnect() {
  if (reconnectTimer !== null) return;
  if (lastUrl === null) return;
  const delay = nextReconnectDelay();
  reconnectAttempts += 1;
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    if (ws === null) ensureSocket(lastUrl);
  }, delay);
}

function cancelReconnect() {
  if (reconnectTimer !== null) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
}

export function ensureSocket(url) {
  if (ws !== null) {
    return;
  }

  lastUrl = url;
  let sock;
  try {
    sock = new WebSocket(url);
    if (typeof window !== "undefined") window.__RALLY_WS__ = sock;
  } catch (e) {
    clearPending();
    scheduleReconnect();
    return;
  }
  ws = sock;
  ws.binaryType = "arraybuffer";

  ws.addEventListener("open", () => {
    if (debugEnabled()) {
      const label = reconnectAttempts > 0 ? "reconnected" : "connected";
      console.log(`%c-- ${label} --`, "color: #33e855; font-weight: bold");
    }
    reconnectAttempts = 0;
    cancelReconnect();
    // Fire onConnect listeners first (triggers page_init which establishes
    // the server-side session), then flush pending commands.
    for (const listener of onConnectListeners) {
      try { listener(); } catch (_) { /* swallow listener exceptions */ }
    }
    // Small delay to let page_init reach the server before commands.
    // Without this, pending sends race with the WS handler setup.
    setTimeout(() => {
      for (const payload of pendingSends) {
        ws.send(payload);
      }
      pendingSends = [];
    }, 50);
  });

  ws.addEventListener("message", (event) => {
    const result = decode_server_frame(event.data);
    if (result instanceof ResultError) {
      if (debugEnabled()) console.warn("runtime: failed to decode server frame", result[0]);
      return;
    }
    const frame = result[0];

    if (frame.kind === "push") {
      // Root API server emissions arrive as push frames tagged by module.
      // Generated setup registers the "to_client" handler, which decodes
      // the typed ToClient value and fans it out through receiver_dispatch.
      logFrame("<<", `push ${frame.module}`, frame.value);
      const handler = pushHandlers.get(frame.module);
      if (handler) handler(frame.value);
      return;
    }

    if (frame.kind === "error") {
      const msg = frame.errors
        ? (Array.isArray(frame.errors)
            ? frame.errors.map(e => (e && e[1]) || "").join("; ")
            : String(frame.errors))
        : "protocol error";
      if (debugEnabled()) console.error("[runtime] protocol error:", msg);
      return;
    }

    // Authentication error detection runs for page-init response frames.
    // The server sends Error("authentication:redirect:<url>") and Error("authentication:forbidden")
    // as wire error responses for authentication policy failures.
    if (handleAuthenticationError(frame)) return;

    if (frame.kind === "response") {
      logFrame("<-", `response #${frame.requestId}`, frame.value);
    }
  });

  ws.addEventListener("close", () => {
    if (!ws) {
      scheduleReconnect();
      return;
    }
    ws = null;
    if (debugEnabled()) {
      console.log("%c-- disconnected --", "color: #e83333; font-weight: bold");
    }
    clearPending();
    for (const listener of onDisconnectListeners) {
      try { listener("connection closed"); } catch (_) { /* swallow */ }
    }
    scheduleReconnect();
  });

  ws.addEventListener("error", () => {
    if (ws) {
      const sock = ws;
      ws = null;
      clearPending();
      for (const listener of onDisconnectListeners) {
        try { listener("connection error"); } catch (_) { /* swallow */ }
      }
      sock.close();
    }
  });
}

/**
 * Register a callback that fires whenever the WebSocket connection
 * opens; both the initial connect and every successful reconnect.
 * Use this to load (or reload) state without a separate code path
 * for the first connection.
 * @param {() => void} callback
 */
export function registerOnConnect(callback) {
  onConnectListeners.add(callback);
}

/**
 * Register a callback that fires when the WebSocket disconnects.
 * The reason is a human-readable string suitable for UX messaging.
 * @param {(reason: string) => void} callback
 */
export function registerOnDisconnect(callback) {
  onDisconnectListeners.add(callback);
}

/**
 * Send a root API command to the server.
 * @param {string} url WebSocket URL
 * @param {string} module wire envelope string, usually "to_server"
 * @param {any} msg the typed ToServer value to encode and send
 */
export function send(url, module, msg) {
  ensureSocket(url);
  const requestId = nextRequestId++;
  const payload = toWebSocketPayload(encode_request(module, requestId, msg));
  logFrame("->", `command #${requestId}`, msg, { module });

  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(payload);
  } else {
    pendingSends.push(payload);
  }
}

/**
 * Send a page init frame with route params. Uses request_id 0 as the
 * init sentinel. The server initializes the page's ServerModel with
 * these params instead of requiring a separate Load message.
 * @param {string} url WebSocket URL
 * @param {string} module page name
 * @param {any} params route params value
 */
export function send_page_init(url, module, params) {
  ensureSocket(url);
  const payload = toWebSocketPayload(encode_request(module, 0, params));
  logFrame("->", `page_init ${module}`, params);
  if (ws && ws.readyState === WebSocket.OPEN) {
    ws.send(payload);
  } else {
    pendingSends.push(payload);
  }
}

/**
 * Register a push handler for a specific module. When the server
 * sends a push frame tagged with this module path, the callback is
 * invoked with the decoded value.
 * @param {string} module shared module path
 * @param {(value: any) => void} callback
 */
export function registerPushHandler(module, callback) {
  pushHandlers.set(module, callback);
}

/**
 * Read SSR flags from window.__RALLY_FLAGS__ and clear them.
 * Returns the base64 ETF string or empty string if not present.
 */
export function read_flags() {
  const flags = window.__RALLY_FLAGS__ || "";
  delete window.__RALLY_FLAGS__;
  return flags;
}

export function read_client_shared_state() {
  const ctx = window.__RALLY_CLIENT_SHARED_STATE__ || "";
  delete window.__RALLY_CLIENT_SHARED_STATE__;
  return ctx;
}
