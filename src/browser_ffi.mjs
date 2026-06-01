export function path() {
  return globalThis.location?.pathname || "/";
}

export function websocket_url() {
  const location = globalThis.location;
  if (!location) return "ws://localhost:8080/ws";
  const protocol = location.protocol === "https:" ? "wss:" : "ws:";
  return `${protocol}//${location.host}/ws`;
}
