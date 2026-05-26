// End-to-end WebSocket smoke test for the Scoreboard root API example.
//
// Builds the client and server packages, starts the server, then verifies
// public/admin Mount isolation and ToClient fanout over plain ETF frames.

import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { once } from "node:events";
import { setTimeout as sleep } from "node:timers/promises";

const root = new URL("..", import.meta.url);
const serverDir = new URL("server/", root);
const clientDir = new URL("client/", root);
const port = 18_374;
const failures = [];

run("gleam", ["build"], clientDir);
run("gleam", ["build"], serverDir);

const server = spawn("gleam", ["run"], {
  cwd: serverDir,
  env: { ...process.env, PORT: String(port) },
  stdio: ["ignore", "pipe", "pipe"],
});

let serverLog = "";
server.stdout.on("data", chunk => {
  serverLog += chunk.toString();
});
server.stderr.on("data", chunk => {
  serverLog += chunk.toString();
});

try {
  await waitFor(() => serverLog.includes(`http://localhost:${port}`), 10_000);

  const protocol = await import(
    "../client/build/dev/javascript/client/generated/protocol_wire.mjs"
  );
  await check("public and admin summaries use explicit global API names", async () => {
    const game = await import(
      "../client/build/dev/javascript/scoreboard_shared/shared/api/domain/game.mjs"
    );

    assert.notDeepEqual(
      Object.keys(game.PublicGameSummary$PublicGameSummary(
        1,
        game.Team$Team("TOR", "Toronto"),
        game.Team$Team("NYC", "New York"),
        10,
        8,
        game.GameStatus$Scheduled(),
      )),
      Object.keys(game.AdminGameSummary$AdminGameSummary(
        1,
        "TOR",
        "NYC",
        10,
        8,
        game.GameStatus$Scheduled(),
        false,
      )),
    );
  });

  await check("root page init response is client-decodable", async () => {
    const ws = await openWs();
    try {
      ws.send(toPayload(protocol.encode_request("Games", 0, null)));

      const event = await nextMessage(ws, 4000);
      const frame = decodeFrame(protocol, event.data);
      assert.equal(frame.kind, "response");
      assert.equal(frame.requestId, 0);
    } finally {
      ws.close();
    }
  });

  await check("served shells use separate mount loaders", async () => {
    const publicHtml = await textAt("/games");
    const adminHtml = await textAt("/admin/games");
    assert.match(publicHtml, /scoreboard_public_client\.mjs/);
    assert.doesNotMatch(publicHtml, /scoreboard_admin_client\.mjs/);
    assert.match(adminHtml, /scoreboard_admin_client\.mjs/);
    assert.doesNotMatch(adminHtml, /scoreboard_public_client\.mjs/);
    assert.ok(publicHtml.includes("@knadh/oat/oat.min.css"));
    assert.ok(adminHtml.includes("@knadh/oat/oat.min.css"));
  });

  await check("served client loaders stay mount isolated", async () => {
    const publicClient = await textAt("/_build/client/scoreboard_public_client.mjs");
    const adminClient = await textAt("/_build/client/scoreboard_admin_client.mjs");
    const globalCodec = await textAt("/_build/client/generated/codec_ffi.mjs");

    assert.ok(!publicClient.includes("shared/api/admin"));
    assert.ok(!publicClient.includes("client/admin"));
    assert.ok(!adminClient.includes("shared/api/public"));
    assert.ok(!adminClient.includes("client/public"));
    assert.ok(!globalCodec.includes("shared/api/public"));
    assert.ok(!globalCodec.includes("shared/api/admin"));
  });

  await check("public mount codec decodes public graph only", async () => {
    run("node", ["test/mount_ws_client.mjs", "public", String(port)], root);
  });

  await check("admin mount codec decodes admin graph only", async () => {
    run("node", ["test/mount_ws_client.mjs", "admin", String(port)], root);
  });

  await check("admin score updates emit admin results without legacy public pushes", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
    );

    const publicWs = await openWs("/ws");
    const adminWs = await openWs("/admin/ws");
    try {
      publicWs.send(toPayload(publicProtocol.encode_request("Games", 0, null)));
      await expectResponse(publicProtocol, publicWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 11, 7, "4th"),
      )));

      const push = await waitForPush(adminProtocol, adminWs);
      assert.equal(push.value.constructor.name, "ScoreUpdateSaved");
      assert.equal(push.value.game.id, 1);
      assert.equal(push.value.game.home_score, 11);
      assert.equal(push.value.game.away_score, 7);
      await expectNoPush(publicProtocol, publicWs, 500);
    } finally {
      publicWs.close();
      adminWs.close();
    }
  });

  await check("admin final and unfinal updates emit admin results only", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
    );

    const standingsWs = await openWs("/ws");
    const adminWs = await openWs("/admin/ws");
    try {
      standingsWs.send(toPayload(publicProtocol.encode_request("Standings", 0, null)));
      await expectResponse(publicProtocol, standingsWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$MarkFinal(1),
      )));

      const finalized = await waitForPush(adminProtocol, adminWs);
      assert.equal(finalized.value.constructor.name, "ResultSaved");
      assert.equal(finalized.value.game.id, 1);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        2,
        adminToServer.ToServer$UpdateScore(1, 12, 7, "4th"),
      )));

      const unfinalized = await waitForPush(adminProtocol, adminWs);
      assert.equal(unfinalized.value.constructor.name, "ScoreUpdateSaved");
      assert.equal(unfinalized.value.game.id, 1);
      await expectNoPush(publicProtocol, standingsWs, 500);
    } finally {
      standingsWs.close();
      adminWs.close();
    }
  });

  await check("game detail loads through public ToServer and ignores admin pushes", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
    );
    const publicToServer = await import(
      "../client/build/dev/javascript/scoreboard_shared/shared/api/to_server.mjs"
    );

    const detailWs = await openWs("/ws");
    const adminWs = await openWs("/admin/ws");
    try {
      detailWs.send(toPayload(publicProtocol.encode_request("GamesId", 0, "2")));
      await expectResponse(publicProtocol, detailWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 13, 7, "4th"),
      )));
      await expectNoPush(publicProtocol, detailWs, 500);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        2,
        adminToServer.ToServer$UpdateScore(2, 5, 3, "OT"),
      )));
      const adminPush = await waitForPush(adminProtocol, adminWs);
      assert.equal(adminPush.value.constructor.name, "ScoreUpdateSaved");
      await expectNoPush(publicProtocol, detailWs, 500);

      detailWs.send(toPayload(publicProtocol.encode_request(
        "to_server",
        1,
        publicToServer.ToServer$LoadGame(2),
      )));
      const push = await waitForPush(publicProtocol, detailWs);
      assert.equal(push.value.constructor.name, "GameLoaded");
      assert.equal(push.value.game.id, 2);
    } finally {
      detailWs.close();
      adminWs.close();
    }
  });
} finally {
  await stopServer();
}

if (failures.length > 0) {
  console.error("\nServer log:\n" + serverLog.trim());
  process.exit(1);
}

console.log("9 websocket smoke checks passed");

async function check(name, fn) {
  try {
    await fn();
    console.log("ok - " + name);
  } catch (error) {
    failures.push(error);
    console.error("not ok - " + name);
    console.error(error.stack || error.message || String(error));
  }
}

function run(command, args, cwd) {
  const result = spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    stdio: "pipe",
  });

  assert.equal(
    result.status,
    0,
    [
      `${command} ${args.join(" ")} failed in ${cwd.pathname}`,
      result.stdout,
      result.stderr,
    ].join("\n"),
  );
}

function toPayload(value) {
  if (value?.rawBuffer instanceof Uint8Array) return value.rawBuffer;
  if (value instanceof Uint8Array) return value;
  if (value instanceof ArrayBuffer) return value;
  throw new Error("Expected a BitArray or binary payload");
}

function decodeFrame(protocol, data) {
  const result = protocol.decode_server_frame(data);
  assert.equal(result.constructor.name, "Ok");
  return result[0];
}

async function expectResponse(protocol, ws, requestId) {
  const frame = decodeFrame(protocol, (await nextMessage(ws, 4000)).data);
  assert.equal(frame.kind, "response");
  assert.equal(frame.requestId, requestId);
}

async function waitForPush(protocol, ws) {
  const deadline = Date.now() + 4000;
  while (Date.now() < deadline) {
    const result = protocol.decode_server_frame(
      (await nextMessage(ws, deadline - Date.now())).data,
    );
    if (result.constructor.name !== "Ok") continue;
    const frame = result[0];
    if (frame.kind === "push" && frame.module === "to_client") return frame;
  }
  throw new Error("Timed out waiting for to_client push");
}

async function expectNoPush(protocol, ws, timeoutMs) {
  try {
    const frame = decodeFrame(protocol, (await nextMessage(ws, timeoutMs)).data);
    if (frame.kind === "push" && frame.module === "to_client") {
      throw new Error("Unexpected to_client push");
    }
  } catch (error) {
    if (String(error.message || error).includes("Timed out waiting")) return;
    throw error;
  }
}

function first(list) {
  assert.equal(list.constructor.name, "NonEmpty");
  return list.head;
}

async function openWs(path = "/ws") {
  const ws = new WebSocket(`ws://127.0.0.1:${port}${path}`);
  ws.binaryType = "arraybuffer";
  await once(ws, "open");
  return ws;
}

async function textAt(path) {
  const response = await fetch(`http://127.0.0.1:${port}${path}`);
  assert.equal(response.status, 200);
  return await response.text();
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

async function waitFor(predicate, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (predicate()) return;
    await sleep(50);
  }

  throw new Error(`Timed out waiting after ${timeoutMs}ms`);
}

async function stopServer() {
  server.kill("SIGKILL");
  await Promise.race([once(server, "exit"), sleep(1000)]);
  server.stdout.destroy();
  server.stderr.destroy();
}
