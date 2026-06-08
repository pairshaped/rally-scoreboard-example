let socket = null;
let socketUrl = null;
let pending = [];
let pendingResults = new Map();
let listeners = new Set();
let reconnectTimer = null;
let reconnectAttempts = 0;
let requestId = 0;
let currentTopicFrame = null;
let sentTopicFrame = null;
const REQUEST_TIMEOUT_MS = 30_000;

import { BitArray, Error as ResultError, List, Ok } from "../../gleam.mjs";
import { None } from "../../../gleam_stdlib/gleam/option.mjs";
import { decode_result_envelope } from "./client_protocol.mjs";
import { ApiLoadError, ApiSaveError } from "./result.mjs";

export function next_request_id() {
  requestId += 1;
  return requestId;
}

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
    new CustomEvent("rally:to-server", {
      detail: { bytes, frame },
    }),
  );
  return undefined;
}

function send_request_frame(requestId, frame) {
  const bytes = bytes_from_bit_array(frame);

  if (socket && socket.readyState === WebSocket.OPEN) {
    socket.send(bytes);
    return undefined;
  }

  pending.push({ kind: "request", requestId, bytes });
  ensure_socket();

  globalThis.dispatchEvent(
    new CustomEvent("rally:to-server", {
      detail: { bytes, frame },
    }),
  );
  return undefined;
}

export function send_topic_frame(topics) {
  const names = Array.from(topics);
  const text = names.length === 0 ? "unsub" : "sub:" + names.join(",");

  if (text === "unsub" && !currentTopicFrame && !sentTopicFrame) {
    pending = pending.filter(frame => !is_topic_frame(frame));
    return undefined;
  }

  currentTopicFrame = text;

  if (socket && socket.readyState === WebSocket.OPEN) {
    if (text === sentTopicFrame) return undefined;
    socket.send(text);
    sentTopicFrame = text;
    return undefined;
  }

  pending = pending.filter(frame => !is_topic_frame(frame));
  pending.push(text);
  ensure_socket();
  return undefined;
}

export function send_load_frame(requestId, frame, onResult, dispatch) {
  pendingResults.set(requestId, pending_result("load", requestId, onResult, dispatch));
  send_request_frame(requestId, frame);
  return undefined;
}

export function send_save_frame(requestId, frame, onResult, dispatch) {
  pendingResults.set(requestId, pending_result("save", requestId, onResult, dispatch));
  send_request_frame(requestId, frame);
  return undefined;
}

function pending_result(kind, requestId, onResult, dispatch) {
  const timer = setTimeout(() => {
    pendingResults.delete(requestId);
    pending = pending.filter(frame =>
      !(frame && frame.kind === "request" && frame.requestId === requestId)
    );
    dispatch(onResult(timeout_result(kind)));
  }, REQUEST_TIMEOUT_MS);

  return { kind, onResult, dispatch, timer };
}

function timeout_result(kind) {
  const message = "Rally request timed out after 30 seconds.";
  if (kind === "save") {
    return new ResultError(List.fromArray([new ApiSaveError(new None(), message)]));
  }
  return new ResultError(List.fromArray([new ApiLoadError(message)]));
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

  globalThis.__rallySocket = socket;
  socket.binaryType = "arraybuffer";

  socket.addEventListener("open", () => {
    reconnectAttempts = 0;
    sentTopicFrame = null;
    const queued = pending;
    pending = [];
    for (const frame of queued) {
      if (is_topic_frame(frame)) {
        socket.send(frame);
        sentTopicFrame = frame;
      } else if (frame && frame.kind === "request") {
        if (pendingResults.has(frame.requestId)) socket.send(frame.bytes);
      } else {
        socket.send(frame);
      }
    }
    if (currentTopicFrame && currentTopicFrame !== sentTopicFrame) {
      socket.send(currentTopicFrame);
      sentTopicFrame = currentTopicFrame;
    }
  });

  socket.addEventListener("message", event => {
    const bytes = event.data instanceof ArrayBuffer
      ? new Uint8Array(event.data)
      : event.data instanceof Uint8Array
      ? event.data
      : null;
    if (!bytes) return;

    const frame = new BitArray(bytes);
    if (dispatch_result_frame(frame)) return;

    for (const listener of listeners) {
      try { listener(frame); } catch (_) {}
    }
  });

  socket.addEventListener("close", () => {
    socket = null;
    sentTopicFrame = null;
    schedule_reconnect();
  });

  socket.addEventListener("error", () => {
    const current = socket;
    socket = null;
    sentTopicFrame = null;
    if (current) current.close();
    schedule_reconnect();
  });
}

function is_topic_frame(frame) {
  return typeof frame === "string" && (frame === "unsub" || frame.startsWith("sub:"));
}

function dispatch_result_frame(frame) {
  if (frame.byteAt(0) !== 2) return false;

  const decoded = decode_result_envelope(frame);
  if (!(decoded instanceof Ok)) return true;

  const [requestId, result] = decoded[0];
  const pending = pendingResults.get(requestId);
  if (!pending) return true;

  pendingResults.delete(requestId);
  clearTimeout(pending.timer);
  pending.dispatch(pending.onResult(result));
  return true;
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
