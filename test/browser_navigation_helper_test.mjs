import assert from "node:assert/strict";

import * as publicPages from "../build/dev/javascript/scoreboard_unified/generated/proute/public/pages.mjs";
import * as browserApp from "../build/dev/javascript/scoreboard_unified/generated/rally/browser_app.mjs";
import * as gamesPage from "../build/dev/javascript/scoreboard_unified/public/pages/games.mjs";
import * as gameDetailPage from "../build/dev/javascript/scoreboard_unified/public/pages/games/id_.mjs";
import * as standingsPage from "../build/dev/javascript/scoreboard_unified/public/pages/standings.mjs";
import * as teamPage from "../build/dev/javascript/scoreboard_unified/public/pages/teams/slug_.mjs";
import { Some } from "../build/dev/javascript/gleam_stdlib/gleam/option.mjs";

assertPath(
  publicPages.Message$GamesMsg(gamesPage.Message$NavigateGame(7)),
  "/games/7",
);
assertPath(
  publicPages.Message$GamesMsg(gamesPage.Message$NavigateTeam("toronto-towers")),
  "/teams/toronto-towers",
);
assertPath(
  publicPages.Message$GamesIdMsg(
    gameDetailPage.Message$NavigateTeam("montreal-meteors"),
  ),
  "/teams/montreal-meteors",
);
assertPath(
  publicPages.Message$StandingsMsg(
    standingsPage.Message$NavigateTeam("toronto-towers"),
  ),
  "/teams/toronto-towers",
);
assertPath(
  publicPages.Message$TeamsSlugMsg(teamPage.Message$NavigateGame(3)),
  "/games/3",
);

function assertPath(message, expected) {
  const path = browserApp.public_message_path(message);
  assert.ok(path instanceof Some, `expected ${expected} navigation path`);
  assert.equal(path[0], expected);
}
