import assert from "node:assert/strict";
import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function readProjectFile(projectPath) {
  return readFileSync(path.join(root, projectPath), "utf8");
}

function gleamFilesUnder(projectDir) {
  const absoluteDir = path.join(root, projectDir);
  return readdirSync(absoluteDir).flatMap((entry) => {
    const absolutePath = path.join(absoluteDir, entry);
    const projectPath = path.relative(root, absolutePath);

    if (statSync(absolutePath).isDirectory()) {
      return gleamFilesUnder(projectPath);
    }

    return projectPath.endsWith(".gleam") ? [projectPath] : [];
  });
}

function assertNoPatterns(projectPath, patterns) {
  const source = readProjectFile(projectPath);

  for (const { pattern, reason } of patterns) {
    assert.doesNotMatch(
      source,
      pattern,
      `${projectPath} leaks Rally-generated plumbing: ${reason}`,
    );
  }
}

const pageModules = [
  ...gleamFilesUnder("src/admin/pages"),
  ...gleamFilesUnder("src/public/pages"),
];

for (const pageModule of pageModules) {
  assertNoPatterns(pageModule, [
    {
      pattern: /generated\/rally\/client_transport/,
      reason: "pages should call the page-facing generated/rally/server API",
    },
    {
      pattern: /generated\/rally\/result/,
      reason: "transport result envelopes are Rally-owned generated plumbing",
    },
    {
      pattern: /generated\/rally\/server_protocol/,
      reason: "wire protocol framing belongs behind generated adapters",
    },
  ]);
}

assertNoPatterns("src/app_ws.gleam", [
  {
    pattern: /generated\/rally\/server_protocol/,
    reason: "websocket request/result protocol calls belong in server_ws",
  },
  {
    pattern: /generated\/rally\/result/,
    reason: "transport result envelopes belong in server_ws",
  },
  {
    pattern: /\bserver_protocol\./,
    reason: "app_ws should consume server_ws, not protocol helpers directly",
  },
  {
    pattern: /\bdecode_[a-z_]+_request\b/,
    reason: "request decoding belongs in server_ws",
  },
  {
    pattern: /\bencode_[a-z_]+_(?:load|save)_result\b/,
    reason: "request result encoding belongs in server_ws",
  },
]);

assertNoPatterns("src/app_ssr.gleam", [
  {
    pattern: /generated\/rally\/result/,
    reason: "SSR should consume server_ssr, not transport result envelopes",
  },
  {
    pattern: /generated\/rally\/server_protocol/,
    reason: "SSR wire protocol framing belongs in server_ssr",
  },
  {
    pattern: /\bserver_protocol\./,
    reason: "SSR should consume server_ssr, not protocol helpers directly",
  },
  {
    pattern: /\bbase64_url_encode\b/,
    reason: "hydration payload encoding belongs in server_ssr",
  },
  {
    pattern: /\bencode_[a-z_]+_load_result\b/,
    reason: "load result frame encoding belongs in server_ssr",
  },
  {
    pattern: /fn\s+\w+_hydration_payload\b/,
    reason: "hydration payload helper functions should be generated",
  },
]);

for (const browserApp of ["src/admin_app.gleam", "src/public_app.gleam"]) {
  assertNoPatterns(browserApp, [
    {
      pattern: /\blustre\.application\b/,
      reason: "browser app startup belongs in browser_app",
    },
    {
      pattern: /\blustre\.start\b/,
      reason: "browser app mounting belongs in browser_app",
    },
    {
      pattern: /\bbrowser_mount\.startup_effects\b/,
      reason: "startup effect wiring belongs in browser_app",
    },
    {
      pattern: /\bbrowser_mount\.push_path\b/,
      reason: "navigation effect wiring belongs in browser_app",
    },
  ]);
}

console.log("Boundary guard checks passed");
