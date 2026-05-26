// Generated. Do not edit.
//
// Browser startup bridge for multi-Mount root API apps.
// Derived from [[tools.rally.clients]] entries and the routes discovered
// for each Mount. It registers the Lustre effect transport, chooses the
// WebSocket URL from the current path, and sends page_init after connect
// so the server can create a RequestContext for this socket.
import { registerTransport } from "./runtime/client_effect_ffi.mjs";
import * as transport from "./transport_ffi.mjs";

export function setup() {
  registerTransport({
    sendToServer: (msg) => {
      const wsUrl = currentWsUrl();
      if (wsUrl) transport.send(wsUrl, "to_server", msg);
    },
  });
  transport.registerOnConnect(() => {
    const wsUrl = currentWsUrl();
    const page = routePageInit();
    if (wsUrl && page) transport.send_page_init(wsUrl, page.module, page.params);
  });
  const wsUrl = currentWsUrl();
  if (wsUrl) transport.ensureSocket(wsUrl);
}

function currentWsUrl() {
  if (typeof window !== "undefined" && window.location.pathname.startsWith("/admin/sign_in")) {
    return null;
  }
  if (typeof window !== "undefined" && window.location.pathname.startsWith("/admin")) {
    return "/admin/ws";
  }
  return "/ws";
}

function routePageInit() {
  if (typeof window === "undefined") return { module: "Games", params: null };

  const path = window.location.pathname.replace(/\/+$/, "") || "/";
  if (path === "/admin/sign_in" || path === "/admin/sign_in/password" || path === "/admin/sign_in/code") {
    return null;
  }
  if (path === "/admin/games") return { module: "AdminGames", params: null };
  if (path === "/standings") return { module: "Standings", params: null };
  const gameMatch = path.match(/^\/games\/([^/]+)$/);
  if (gameMatch) return { module: "GamesId", params: decodeURIComponent(gameMatch[1]) };
  return { module: "Games", params: null };
}
