import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { execFileSync, spawn } from "node:child_process";
import path from "node:path";

const baseUrl = process.env.SCOREBOARD_BASE_URL ?? "http://localhost:8080";

const { chromium } = loadPlaywright();

let server = null;
let browser = null;

try {
  await step("start server", ensureServer);
  await step("assert /games SSR document", () => assertSsrDocument("/games", [
    "data-hydration=",
    "Toronto Towers",
    "Montreal Meteors",
  ]));

  browser = await step("launch browser", () => chromium.launch());
  const context = await browser.newContext();
  const page = await context.newPage();
  page.setDefaultTimeout(8_000);
  page.setDefaultNavigationTimeout(12_000);
  const sentFrames = [];

  page.on("websocket", socket => {
    socket.on("framesent", frame => {
      sentFrames.push(frame.payload);
    });
  });

  await step("load hydrated /games", () =>
    page.goto(url("/games"), { waitUntil: "domcontentloaded" }),
  );
  await step("see public SSR game data", async () => {
    await page.getByText("Toronto Towers").first().waitFor();
    await page.getByText("Montreal Meteors").first().waitFor();
  });
  await page.waitForTimeout(500);

  assert.equal(
    await page.locator("#app").getAttribute("data-hydration"),
    null,
    "hydration data should be consumed after browser boot",
  );
  assert.equal(
    sentFrames.length,
    0,
    "hydrated direct /games load should not send an initial websocket load request",
  );

  await step("navigate to game detail", async () => {
    await page.getByRole("link", { name: "Details" }).first().click();
    await page.waitForURL("**/games/1");
    await page.getByText("Scoring summary").waitFor();
    await page.getByText("3rd").first().waitFor();
  });
  assert.ok(
    sentFrames.length > 0,
    "SPA navigation should send a websocket load request for the destination page",
  );

  await step("browser back returns to games", async () => {
    await page.goBack();
    await page.waitForURL("**/games");
    await page.getByRole("heading", { name: "Today" }).waitFor();
  });

  await step("sign in to admin", async () => {
    await page.goto(url("/sign_in?return_to=/admin/games"), {
      waitUntil: "domcontentloaded",
    });
    await page.getByLabel("Sign-in code").fill("A1Z9Q");
    await page.getByRole("button", { name: "Sign In" }).click();
    await page.waitForURL("**/admin/games");
    await page.getByText("Admin score desk").waitFor();
    await page.getByText("Finalize").first().waitFor();
  });

} finally {
  if (browser) {
    await browser.close();
  }
  if (server) {
    server.kill("SIGTERM");
  }
}

function loadPlaywright() {
  const localRequire = createRequire(import.meta.url);

  try {
    return localRequire("playwright");
  } catch (_) {
    let cliPath;
    try {
      cliPath = execFileSync(
        "sh",
        ["-lc", "readlink -f $(command -v playwright)"],
        { encoding: "utf8" },
      ).trim();
    } catch {
      throw new Error(
        "Playwright is not installed. Install it globally with `pnpm add -g playwright`.",
      );
    }

    const packageRoot = path.dirname(cliPath);
    return createRequire(path.join(packageRoot, "package.json"))("playwright");
  }
}

async function ensureServer() {
  if (await isServing()) return;

  server = spawn("gleam", ["run"], {
    cwd: process.cwd(),
    env: process.env,
    stdio: ["ignore", "pipe", "pipe"],
  });

  let output = "";
  server.stdout.on("data", chunk => {
    output += chunk.toString();
  });
  server.stderr.on("data", chunk => {
    output += chunk.toString();
  });

  const deadline = Date.now() + 20_000;
  while (Date.now() < deadline) {
    if (server.exitCode !== null) {
      throw new Error("Server exited before becoming ready:\n" + output);
    }
    if (await isServing()) return;
    await sleep(250);
  }

  throw new Error("Timed out waiting for server:\n" + output);
}

async function isServing() {
  try {
    const response = await fetch(url("/games"));
    return response.ok;
  } catch {
    return false;
  }
}

async function assertSsrDocument(route, expected) {
  const response = await fetch(url(route));
  assert.equal(response.status, 200);
  const html = await response.text();

  assert.notEqual(
    html,
    '<div id="app"></div>',
    "SSR document should not be an empty app root",
  );

  for (const text of expected) {
    assert.ok(
      html.includes(text),
      `SSR document for ${route} should contain ${JSON.stringify(text)}`,
    );
  }
}

function url(route) {
  return new URL(route, baseUrl).toString();
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function step(name, work) {
  process.stdout.write(`browser smoke: ${name}\n`);
  return await work();
}
