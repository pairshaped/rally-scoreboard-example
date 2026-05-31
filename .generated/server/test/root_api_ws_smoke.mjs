// End-to-end WebSocket smoke test for the Scoreboard root API example.
//
// Builds the client and server packages, starts the server, then verifies
// public/admin Mount isolation and ToClient fanout over plain ETF frames.

import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { once } from "node:events";
import { createServer } from "node:net";
import { setTimeout as sleep } from "node:timers/promises";

const root = new URL("../../", import.meta.url);
const serverDir = new URL("server/", root);
const clientDir = new URL("client/", root);
const port = await freePort();
const failures = [];

let cookies = "";

async function freePort() {
  const server = createServer();
  server.unref();

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });

  const address = server.address();
  const port = typeof address === "object" && address ? address.port : 18_374;

  await new Promise((resolve, reject) => {
    server.close(error => error ? reject(error) : resolve());
  });

  return port;
}

function updateCookies(response) {
  const setCookie = response.headers.getSetCookie?.() || [];
  for (const cookie of setCookie) {
    const [pair] = cookie.split(";");
    const [name, ...rest] = pair.split("=");
    const value = rest.join("=");
    const re = new RegExp(`(?:^|; )${name}=[^;]*`);
    if (cookies.match(re)) {
      cookies = cookies.replace(re, `${name}=${value}`);
    } else {
      cookies = cookies ? `${cookies}; ${name}=${value}` : `${name}=${value}`;
    }
  }
}

async function signIn() {
  const res1 = await fetch(`http://127.0.0.1:${port}/sign_in?return_to=/admin/games`, {
    redirect: "manual",
  });
  updateCookies(res1);

  const res2 = await fetch(`http://127.0.0.1:${port}/sign_in`, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Cookie: cookies,
    },
    body: "email=admin@example.com&code=A1Z9Q&return_to=/admin/games",
    redirect: "manual",
  });
  updateCookies(res2);
}

run("gleam", ["run", "-m", "marmot", "reset"], serverDir);
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

let serverExited = false;
let serverDied = null;
server.on("exit", (code) => {
  serverExited = true;
  serverLog += `\n[server exited with code ${code}]\n`;
  serverDied = new Error(`Server died with code ${code}:\n${serverLog.trim()}`);
});

function rejectIfServerDead() {
  if (serverDied) throw serverDied;
}

try {
  await waitFor(
    () => serverLog.includes(`http://localhost:${port}`) || serverExited,
    15_000,
  );
  if (serverExited) {
    throw new Error(`Server exited before becoming ready:\n${serverLog.trim()}`);
  }

  const protocol = await import(
    "../../client/build/dev/javascript/client/generated/protocol_wire.mjs"
  );
  await check("public and admin summaries use explicit global API names", async () => {
    const game = await import(
      "../../client/build/dev/javascript/client/shared/api/domain/game.mjs"
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

  await check("unauthenticated admin websocket is rejected", async () => {
    const url = `ws://127.0.0.1:${port}/admin/ws`;
    const ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";
    let closed = false;
    try {
      const outcome = await Promise.race([
        once(ws, "open").then(() => "opened"),
        once(ws, "error").then(() => "error"),
        new Promise((r) => setTimeout(() => r("timeout"), 3000)),
      ]);
      if (outcome === "opened") {
        ws.close();
        throw new Error("Expected unauthenticated admin websocket to be rejected");
      }
      if (outcome === "timeout") {
        ws.close();
        throw new Error("Timed out waiting for admin websocket rejection");
      }
    } finally {
      if (!closed) {
        try { ws.close(); } catch (_) { /* ignore */ }
      }
    }
  });

  await check("admin sign-in succeeds", async () => {
    await signIn();
    // Verify sign-in worked by fetching an authenticated page.
    // redirect: "manual" so a 303 redirect to sign-in (auth failure)
    // does not silently follow and return 200 from the sign-in page.
    const response = await fetch(`http://127.0.0.1:${port}/admin/games`, {
      headers: { Cookie: cookies },
      redirect: "manual",
    });
    assert.equal(response.status, 200);
  });

  await check("seed data is a six-team round robin", async () => {
    assert.equal(sqliteValue("SELECT COUNT(*) FROM teams;"), "6");
    assert.equal(sqliteValue("SELECT COUNT(*) FROM games;"), "15");
    assert.equal(
      sqliteValue(
        "SELECT COUNT(*) FROM (SELECT CASE WHEN home_code < away_code THEN home_code || '-' || away_code ELSE away_code || '-' || home_code END AS pair FROM games GROUP BY pair HAVING COUNT(*) = 1);",
      ),
      "15",
    );
    assert.equal(
      sqliteValue(
        "SELECT COUNT(*) FROM games WHERE home_code = away_code;",
      ),
      "0",
    );
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
    run("node", ["test/mount_ws_client.mjs", "public", String(port)], serverDir);
  });

  await check("admin mount codec decodes admin graph only", async () => {
    run("node", ["test/mount_ws_client.mjs", "admin", String(port)], serverDir);
  });

  await check("admin score updates emit admin results without legacy public pushes", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
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

      const liveUpdate = await waitForPush(publicProtocol, publicWs);
      assert.equal(liveUpdate.value.constructor.name, "GameUpdated");
      assert.equal(liveUpdate.value.game.id, 1);
      assert.equal(liveUpdate.value.game.home_score, 11);
      assert.equal(liveUpdate.value.game.away_score, 7);
    } finally {
      publicWs.close();
      adminWs.close();
    }
  });

  await check("admin game tabs receive live score broadcasts", async () => {
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const senderWs = await openWs("/admin/ws");
    const observerWs = await openWs("/admin/ws");
    try {
      senderWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, senderWs, 0);

      observerWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, observerWs, 0);

      senderWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 16, 11, "4th"),
      )));

      const senderPush = await waitForPushMatching(
        adminProtocol,
        senderWs,
        "ScoreUpdateSaved",
      );
      assert.equal(senderPush.value.game.id, 1);

      const observerPush = await waitForPushMatching(
        adminProtocol,
        observerWs,
        "GameUpdated",
      );
      assert.equal(observerPush.value.game.id, 1);
      assert.equal(observerPush.value.game.home_score, 16);
      assert.equal(observerPush.value.game.away_score, 11);
    } finally {
      senderWs.close();
      observerWs.close();
    }
  });

  await check("admin score update persists across SSR reload", async () => {
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const adminWs = await openWs("/admin/ws");
    try {
      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 14, 9, "4th"),
      )));
      const push = await waitForPush(adminProtocol, adminWs);
      assert.equal(push.value.constructor.name, "ScoreUpdateSaved");
      assert.equal(push.value.game.id, 1);
      assert.equal(push.value.game.home_score, 14);
      assert.equal(push.value.game.away_score, 9);

      const reloadedAdminHtml = await textAt("/admin/games");
      assert.match(
        reloadedAdminHtml,
        /<strong[^>]*>MTL<\/strong>[\s\S]*?<span class="score">9<\/span>[\s\S]*?<strong[^>]*>TOR<\/strong>[\s\S]*?<span class="score">14<\/span>/,
      );
    } finally {
      adminWs.close();
    }
  });

  await check("admin score update writes through to SQLite", async () => {
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const adminWs = await openWs("/admin/ws");
    try {
      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 15, 10, "4th"),
      )));
      const push = await waitForPush(adminProtocol, adminWs);
      assert.equal(push.value.constructor.name, "ScoreUpdateSaved");
      assert.equal(push.value.game.id, 1);

      assert.equal(
        sqliteValue(
          "SELECT home_score || '|' || away_score || '|' || period FROM games WHERE id = 1;",
        ),
        "15|10|4th",
      );
    } finally {
      adminWs.close();
    }
  });

  await check("admin final broadcasts GameUpdated to public sockets", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const standingsWs = await openWs("/ws");
    const adminWs = await openWs("/admin/ws");
    try {
      standingsWs.send(toPayload(publicProtocol.encode_request("Standings", 0, null)));
      await expectResponse(publicProtocol, standingsWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      const finalizedPromise = waitForPushMatching(
        adminProtocol,
        adminWs,
        "ResultSaved",
      );
      const standingsPushPromise = waitForPushMatching(
        publicProtocol,
        standingsWs,
        "GameUpdated",
      );
      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$MarkFinal(1),
      )));

      const finalized = await finalizedPromise;
      assert.equal(finalized.value.constructor.name, "ResultSaved");
      assert.equal(finalized.value.game.id, 1);

      const unfinalizedPromise = waitForPushMatching(
        adminProtocol,
        adminWs,
        "ScoreUpdateSaved",
      );
      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        2,
        adminToServer.ToServer$UpdateScore(1, 12, 7, "4th"),
      )));

      const unfinalized = await unfinalizedPromise;
      assert.equal(unfinalized.value.constructor.name, "ScoreUpdateSaved");
      assert.equal(unfinalized.value.game.id, 1);

      // MarkFinal broadcasts GameUpdated through the live_updates.broadcast
      // path. GameUpdated arrival proves the transport.
      const markFinalPush = await standingsPushPromise;
      assert.equal(
        markFinalPush.value.constructor.name,
        "GameUpdated",
      );
      assert.equal(markFinalPush.value.game.id, 1);
    } finally {
      standingsWs.close();
      adminWs.close();
    }
  });

  await check("game detail receives live GameUpdated from admin score changes", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );
    const publicToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
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
      const live1 = await waitForPush(publicProtocol, detailWs);
      assert.equal(live1.value.constructor.name, "GameUpdated");
      assert.equal(live1.value.game.id, 1);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        2,
        adminToServer.ToServer$UpdateScore(2, 5, 3, "OT"),
      )));
      const adminPush = await waitForPushMatching(
        adminProtocol,
        adminWs,
        "ScoreUpdateSaved",
      );
      assert.equal(adminPush.value.constructor.name, "ScoreUpdateSaved");
      const live2 = await waitForPush(publicProtocol, detailWs);
      assert.equal(live2.value.constructor.name, "GameUpdated");
      assert.equal(live2.value.game.id, 2);

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

  await check("team detail receives live updates for its games", async () => {
    const publicProtocol = protocol;
    const adminProtocol = protocol;
    const adminToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const teamWs = await openWs("/ws");
    const adminWs = await openWs("/admin/ws");
    try {
      teamWs.send(toPayload(publicProtocol.encode_request(
        "Team",
        0,
        "montréal-meteors",
      )));
      await expectResponse(publicProtocol, teamWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request("AdminGames", 0, null)));
      await expectResponse(adminProtocol, adminWs, 0);

      adminWs.send(toPayload(adminProtocol.encode_request(
        "to_server",
        1,
        adminToServer.ToServer$UpdateScore(1, 17, 12, "4th"),
      )));

      const teamPush = await waitForPushMatching(
        publicProtocol,
        teamWs,
        "GameUpdated",
      );
      assert.equal(teamPush.value.game.id, 1);
      assert.equal(teamPush.value.game.home_score, 17);
      assert.equal(teamPush.value.game.away_score, 12);
    } finally {
      teamWs.close();
      adminWs.close();
    }
  });

  await check("non-ASCII team slug round-trips through LoadTeam", async () => {
    const publicProtocol = protocol;
    const publicToServer = await import(
      "../../client/build/dev/javascript/client/shared/api/to_server.mjs"
    );

    const ws = await openWs("/ws");
    try {
      ws.send(toPayload(publicProtocol.encode_request("Games", 0, null)));
      await expectResponse(publicProtocol, ws, 0);

      ws.send(toPayload(publicProtocol.encode_request(
        "to_server",
        1,
        publicToServer.ToServer$LoadTeam("montréal-meteors"),
      )));
      const push = await waitForPush(publicProtocol, ws);
      assert.equal(push.value.constructor.name, "TeamLoaded");
      assert.equal(push.value.team.slug, "montréal-meteors");
      assert.equal(push.value.team.code, "MTL");
      assert.equal(push.value.team.name, "Montreal Meteors");
    } finally {
      ws.close();
    }
  });
  await check("SSR renders game content in /games HTML", async () => {
    const html = await textAt("/games");
    assert.match(html, /<div id="app">/);
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(html, /Toronto Towers/);
    assert.match(html, /Montreal Meteors/);
    // Game 2 (VAN–NYC, Final) is never modified by the WS tests.
    assert.match(html, /Vancouver Voyagers/);
    assert.match(html, /New York Comets/);
    assert.match(html, /Final/);
  });

  await check("SSR renders standings content in /standings HTML", async () => {
    const html = await textAt("/standings");
    assert.match(html, /<div id="app">/);
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(html, /Toronto Towers/);
    assert.match(html, /Montreal Meteors/);
    assert.match(html, /<th[^>]*>Team<\/th>/);
    assert.match(html, /<th[^>]*>W<\/th>\s*<th[^>]*>L<\/th>/);
    assert.match(html, /<th[^>]*>PF<\/th>\s*<th[^>]*>PA<\/th>/);
  });

  await check("SSR renders game detail in /games/1 HTML", async () => {
    const html = await textAt("/games/1");
    assert.match(html, /<div id="app">/);
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(html, /Toronto Towers/);
    assert.match(html, /Montreal Meteors/);
    assert.match(html, /Scoring summary/);
  });

  await check("SSR respects team query filter on /games?team=TOR", async () => {
    const allHtml = await textAt("/games");
    const filteredHtml = await textAt("/games?team=TOR");
    assert.match(filteredHtml, /<div id="app">/);
    assert.match(filteredHtml, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(filteredHtml, /Toronto Towers/);
    // Seeded game 3 is BOS-LAK, so it should appear in all-games but not
    // in the TOR filter. Team names are not enough because every team plays TOR
    // somewhere in a round robin.
    assert.match(allHtml, /href="\/games\/3"/);
    assert.ok(
      !filteredHtml.includes('href="/games/3"'),
      "Filtered /games?team=TOR should not contain game 3",
    );
  });

  await check("SSR renders team detail in /teams/toronto-towers HTML", async () => {
    const html = await textAt("/teams/toronto-towers");
    assert.match(html, /<div id="app">/);
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(html, /Toronto Towers/);
    assert.match(html, /TOR/);
    assert.match(html, /W-L/);
  });

  await check("SSR hydration data decodes as valid ETF", async () => {
    const html = await textAt("/games");
    const match = html.match(/window\.__RUNTIME_SSR_TO_CLIENT__='([^']+)'/);
    assert.ok(match, "SSR ToClient script tag missing");
    const raw = match[1];
    assert.ok(raw.length > 0, "SSR ToClient state should be non-empty");
    const binary = atob(raw);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
    assert.equal(bytes[0], 131, "SSR ToClient state must be valid ETF (version byte 131)");
    assert.ok(bytes.length > 3, "SSR ToClient ETF payload too short to contain game data");
  });

  await check("SSR embeds ClientSharedState separately from page hydration data", async () => {
    const html = await textAt("/games");
    assert.match(html, /window\.__RUNTIME_CLIENT_SHARED_STATE__='[^']+'/);
    const match = html.match(/window\.__RUNTIME_CLIENT_SHARED_STATE__='([^']+)'/);
    assert.ok(match, "ClientSharedState script tag missing");
    const raw = match[1];
    assert.ok(raw.length > 0, "ClientSharedState should be non-empty");
    // Both variables coexist independently on the same page.
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
  });

  await check("Admin SSR renders /admin/games with content and hydration data", async () => {
    const html = await textAt("/admin/games");
    assert.match(html, /<div id="app">/);
    assert.match(html, /window\.__RUNTIME_SSR_TO_CLIENT__='[^']+'/);
    assert.match(html, /TOR/);
    assert.match(html, /NYC/);
    assert.match(html, /Finalize/);
  });
} finally {
  await stopServer();
}

if (failures.length > 0) {
  console.error("\nServer log:\n" + serverLog.trim());
  process.exit(1);
}

console.log("24 smoke checks passed");

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

function sqliteValue(sql) {
  const result = spawnSync("sqlite3", ["db/scoreboard.db", sql], {
    cwd: serverDir,
    encoding: "utf8",
    stdio: "pipe",
  });

  assert.equal(
    result.status,
    0,
    [
      "sqlite3 query failed",
      result.stdout,
      result.stderr,
    ].join("\n"),
  );

  return result.stdout.trim();
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

async function waitForPushMatching(protocol, ws, constructorName) {
  const deadline = Date.now() + 4000;
  while (Date.now() < deadline) {
    const frame = await waitForPush(protocol, ws);
    if (frame.value.constructor.name === constructorName) return frame;
  }
  throw new Error(`Timed out waiting for ${constructorName} push`);
}

function first(list) {
  assert.equal(list.constructor.name, "NonEmpty");
  return list.head;
}

async function openWs(path = "/ws", opts = {}) {
  const url = `ws://127.0.0.1:${port}${path}`;
  const ws = cookies
    ? new WebSocket(url, { headers: { Cookie: cookies } })
    : new WebSocket(url);
  ws.binaryType = "arraybuffer";

  let cancelled = false;
  const timeout = setTimeout(() => {
    cancelled = true;
    ws.close();
  }, 10_000);

  try {
    const outcome = await Promise.race([
      once(ws, "open").then(() => "opened"),
      once(ws, "error").then(() => "error"),
      (async () => {
        while (!serverDied && !cancelled) await sleep(200);
        if (cancelled) return "cancelled";
        throw serverDied;
      })(),
    ]);

    if (outcome === "error") {
      ws.close();
      throw new Error(`WebSocket error opening ${path}`);
    }
    if (outcome === "cancelled") {
      throw new Error(`Timed out opening ${path} (server alive)`);
    }

    rejectIfServerDead();
    return ws;
  } finally {
    clearTimeout(timeout);
    cancelled = true;
  }
}

async function textAt(path) {
  const opts = cookies ? { headers: { Cookie: cookies } } : {};
  const response = await fetch(`http://127.0.0.1:${port}${path}`, opts);
  if (response.status !== 200) {
    const body = await response.text().catch(() => "");
    throw new Error(`Expected 200 for ${path}, got ${response.status}: ${body.slice(0, 200)}`);
  }
  return await response.text();
}

function nextMessage(ws, timeoutMs) {
  return Promise.race([
    new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        ws.removeEventListener("message", onMessage);
        reject(new Error("Timed out waiting for websocket frame"));
      }, timeoutMs);

      function onMessage(event) {
        clearTimeout(timer);
        resolve(event);
      }

      ws.addEventListener("message", onMessage, { once: true });
    }),
    (async () => {
      while (!serverDied) await sleep(100);
      throw serverDied;
    })(),
  ]);
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
