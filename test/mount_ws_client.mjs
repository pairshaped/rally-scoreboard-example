// WebSocket smoke helper for one Scoreboard Mount.
//
// Used by shell scripts or humans to connect to the running server and
// exercise public or admin root API flows without opening a browser.

import assert from "node:assert/strict";
import { once } from "node:events";

const mount = process.argv[2];
const port = process.argv[3];

if (!mount || !port) {
  throw new Error("Usage: node mount_ws_client.mjs <public|admin> <port>");
}

if (mount === "public") {
  await runPublic();
} else if (mount === "admin") {
  await runAdmin();
} else {
  throw new Error("Unknown Mount: " + mount);
}

async function runPublic() {
  const protocol = await import(
    "../client/build/dev/javascript/client/generated/protocol_wire.mjs"
  );
  const toServer = await import(
    "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
  );
  const ws = await openWs("/ws");
  try {
    ws.send(toPayload(protocol.encode_request("Games", 0, null)));
    await expectResponse(protocol, ws, 0);

    ws.send(toPayload(protocol.encode_request(
      "to_server",
      1,
      toServer.ToServer$LoadGames(),
    )));

    const push = await waitForPush(protocol, ws);
    assert.equal(push.value.constructor.name, "GamesLoaded");

    const summary = first(push.value.games);
    assert.equal(summary.constructor.name, "PublicGameSummary");
    assert.equal(summary.home.constructor.name, "Team");
    assert.equal(typeof summary.home_code, "undefined");

    ws.send(toPayload(protocol.encode_request(
      "to_server",
      2,
      toServer.ToServer$LoadStandings(),
    )));

    const standings = await waitForPush(protocol, ws);
    assert.equal(standings.value.constructor.name, "StandingsLoaded");
    const row = first(standings.value.rows);
    assert.equal(row.constructor.name, "StandingRow");
    assert.equal(typeof row.team_code, "string");
  } finally {
    ws.close();
  }
}

async function runAdmin() {
  const protocol = await import(
    "../client/build/dev/javascript/client/generated/protocol_wire.mjs"
  );
  const toServer = await import(
    "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
  );
  const ws = await openWs("/admin/ws");
  try {
    ws.send(toPayload(protocol.encode_request("AdminGames", 0, null)));
    await expectResponse(protocol, ws, 0);

    ws.send(toPayload(protocol.encode_request(
      "to_server",
      1,
      toServer.ToServer$CreateGame("TOR", "NYC"),
    )));
    const created = await waitForPush(protocol, ws);
    assert.equal(created.value.constructor.name, "GameCreated");
    assert.equal(created.value.game.constructor.name, "AdminGameDetail");

    ws.send(toPayload(protocol.encode_request(
      "to_server",
      2,
      toServer.ToServer$LoadAdminGames(),
    )));
    const loaded = await waitForPush(protocol, ws);
    assert.equal(loaded.value.constructor.name, "AdminGamesLoaded");

    const summary = first(loaded.value.games);
    assert.equal(summary.constructor.name, "AdminGameSummary");
    assert.equal(typeof summary.home_code, "string");
    assert.equal(typeof summary.home, "undefined");
  } finally {
    ws.close();
  }
}

async function openWs(path) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}${path}`);
  ws.binaryType = "arraybuffer";
  await once(ws, "open");
  return ws;
}

async function expectResponse(protocol, ws, requestId) {
  const frame = decodeFrame(protocol, (await nextMessage(ws, 4000)).data);
  assert.equal(frame.kind, "response");
  assert.equal(frame.requestId, requestId);
}

async function waitForPush(protocol, ws) {
  const frame = decodeFrame(protocol, (await nextMessage(ws, 4000)).data);
  assert.equal(frame.kind, "push");
  assert.equal(frame.module, "to_client");
  return frame;
}

function decodeFrame(protocol, data) {
  const result = protocol.decode_server_frame(data);
  assert.equal(result.constructor.name, "Ok");
  return result[0];
}

function toPayload(value) {
  if (value?.rawBuffer instanceof Uint8Array) return value.rawBuffer;
  if (value instanceof Uint8Array) return value;
  if (value instanceof ArrayBuffer) return value;
  throw new Error("Expected a BitArray or binary payload");
}

function first(list) {
  assert.equal(list.constructor.name, "NonEmpty");
  return list.head;
}

function nextMessage(ws, timeoutMs) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      ws.removeEventListener("message", onMessage);
      reject(new Error("Timed out waiting for websocket frame"));
    }, timeoutMs);

    function onMessage(event) {
      clearTimeout(timer);
      resolve(event);
    }

    ws.addEventListener("message", onMessage, { once: true });
  });
}
