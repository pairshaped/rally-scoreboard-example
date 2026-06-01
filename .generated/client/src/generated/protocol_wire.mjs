// Generated. Do not edit.
//
// Workspace protocol facade used by the shared client transport.
// Importing codec_ffi.mjs keeps the generated protocol surface present before
// this facade decodes typed ETF values.
// Derived from shared/api/to_server.gleam, shared/api/to_client.gleam,
// and client/src/generated/codec_ffi.mjs.

import "./codec_ffi.mjs";
import { Ok, Error as ResultError } from "../../gleam_stdlib/gleam.mjs";

function normalizeInput(input) {
  if (input instanceof Uint8Array) return input;
  if (input instanceof ArrayBuffer) return new Uint8Array(input);
  if (input && input.rawBuffer instanceof Uint8Array) return input.rawBuffer;
  return new Uint8Array(input);
}

function decodeError(message) {
  return new ResultError(message);
}

export function identity(value) {
  return value;
}

export function encode_request(_module, _requestId, _value) {
  // TODO: Rust generator emits ETF request encoding here.
  return new Uint8Array();
}

export function decode_server_frame(data) {
  try {
    const bytes = normalizeInput(data);
    if (bytes.length < 1) return decodeError("invalid server frame: empty");
    return decodeError("rust ETF frame decoder not generated yet");
  } catch (e) {
    return decodeError(e && e.message ? e.message : String(e));
  }
}

export function encode_flags(_value) {
  // TODO: Rust generator emits SSR boot flag encoding here.
  return "";
}

export function decode_flags_typed(_value, _typeName) {
  // TODO: Rust generator emits typed SSR boot flag decoding here.
  return decodeError("rust ETF flag decoder not generated yet");
}

export function decode_safe(_bytes) {
  // TODO: Rust generator emits generic ETF decoding here.
  return decodeError("rust ETF decoder not generated yet");
}
