let socket = null;
let socketUrl = null;
let pending = [];
let listeners = new Set();
let reconnectTimer = null;
let reconnectAttempts = 0;

import { BitArray } from "../gleam.mjs";

export function connect(url, onFrame) {
  socketUrl = url;
  listeners.add(onFrame);
  ensure_socket();
  return undefined;
}

export function send_frame(frame) {
  const bytes = bytes_from_bit_array(frame);

  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(bytes);
    return undefined;
  }

  pending.push(bytes);
  ensure_socket();

  globalThis.dispatchEvent(
    new CustomEvent("scoreboard:to-server", {
      detail: { bytes, frame },
    }),
  );
  return undefined;
}

function ensure_socket() {
  if (!socketUrl || socket) return;

  try {
    socket = new WebSocket(socketUrl);
  } catch (_) {
    socket = null;
    schedule_reconnect();
    return;
  }

  globalThis.__scoreboardSocket = socket;
  socket.binaryType = "arraybuffer";

  socket.addEventListener("open", () => {
    reconnectAttempts = 0;
    const queued = pending;
    pending = [];
    for (const bytes of queued) socket.send(bytes);
  });

  socket.addEventListener("message", event => {
    const bytes = event.data instanceof ArrayBuffer
      ? new Uint8Array(event.data)
      : event.data instanceof Uint8Array
      ? event.data
      : null;
    if (!bytes) return;

    const frame = new BitArray(bytes);
    for (const listener of listeners) {
      try { listener(frame); } catch (_) {}
    }
  });

  socket.addEventListener("close", () => {
    socket = null;
    schedule_reconnect();
  });

  socket.addEventListener("error", () => {
    const current = socket;
    socket = null;
    if (current) current.close();
    schedule_reconnect();
  });
}

function schedule_reconnect() {
  if (reconnectTimer || !socketUrl) return;
  const cap = Math.min(500 * Math.pow(2, reconnectAttempts), 30_000);
  reconnectAttempts += 1;
  const delay = cap / 2 + Math.random() * (cap / 2);
  reconnectTimer = setTimeout(() => {
    reconnectTimer = null;
    ensure_socket();
  }, delay);
}

function bytes_from_bit_array(frame) {
  if (frame?.rawBuffer instanceof Uint8Array) return frame.rawBuffer;
  if (frame?.buffer instanceof Uint8Array) return frame.buffer;
  if (frame instanceof Uint8Array) return frame;
  if (frame instanceof ArrayBuffer) return new Uint8Array(frame);
  throw new Error("Expected a Gleam BitArray frame");
}
