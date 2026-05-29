// Generated. Do not edit.
//
// Plain ETF constructor registry for the root API graph.
// Derived from shared/api/to_server.gleam, shared/api/to_client.gleam,
// every exported wire-visible custom type under shared/api/domain/,
// shared/authentication_context, and per-Mount ClientSharedState types
// under shared/admin/ and shared/public/.
//
// Module paths are intentionally absent from wire identity. Constructor
// atoms must be unique across the whole shared API graph.

import { registerConstructor } from "../../libero/libero/etf/wire_ffi.mjs";
import * as toServer from "../../scoreboard_shared/shared/api/to_server.mjs";
import * as toClient from "../../scoreboard_shared/shared/api/to_client.mjs";
import * as game from "../../scoreboard_shared/shared/api/domain/game.mjs";
import * as standing from "../../scoreboard_shared/shared/api/domain/standing.mjs";
import * as team from "../../scoreboard_shared/shared/api/domain/team.mjs";
import * as authenticationContext from "../../scoreboard_shared/shared/authentication_context.mjs";
import * as adminClientSharedState from "../../scoreboard_shared/shared/admin/client_shared_state.mjs";
import * as publicClientSharedState from "../../scoreboard_shared/shared/public/client_shared_state.mjs";

registerConstructor("load_games", toServer.LoadGames, 0);
registerConstructor("load_game", toServer.LoadGame, 1);
registerConstructor("load_standings", toServer.LoadStandings, 0);
registerConstructor("load_team", toServer.LoadTeam, 1);
registerConstructor("load_admin_games", toServer.LoadAdminGames, 0);
registerConstructor("create_game", toServer.CreateGame, 2);
registerConstructor("update_score", toServer.UpdateScore, 4);
registerConstructor("mark_final", toServer.MarkFinal, 1);
registerConstructor("correct_result", toServer.CorrectResult, 3);
registerConstructor("games_loaded", toClient.GamesLoaded, 1);
registerConstructor("game_loaded", toClient.GameLoaded, 1);
registerConstructor("standings_loaded", toClient.StandingsLoaded, 1);
registerConstructor("power_rankings_loaded", toClient.PowerRankingsLoaded, 1);
registerConstructor("game_updated", toClient.GameUpdated, 1);
registerConstructor("games_load_failed", toClient.GamesLoadFailed, 1);
registerConstructor("team_loaded", toClient.TeamLoaded, 1);
registerConstructor("admin_games_loaded", toClient.AdminGamesLoaded, 1);
registerConstructor("game_created", toClient.GameCreated, 1);
registerConstructor("score_update_saved", toClient.ScoreUpdateSaved, 1);
registerConstructor("result_saved", toClient.ResultSaved, 1);
registerConstructor("admin_error", toClient.AdminError, 1);
registerConstructor("team", game.Team, 3);
registerConstructor("public_game_summary", game.PublicGameSummary, 6);
registerConstructor("game_detail", game.GameDetail, 7);
registerConstructor("game_snapshot", game.GameSnapshot, 6);
registerConstructor("admin_game_summary", game.AdminGameSummary, 7);
registerConstructor("admin_game_detail", game.AdminGameDetail, 7);
registerConstructor("scheduled", game.Scheduled, 0);
registerConstructor("live", game.Live, 1);
registerConstructor("final", game.Final, 0);
registerConstructor("standing_row", standing.StandingRow, 7);
registerConstructor("power_ranking_row", standing.PowerRankingRow, 7);
registerConstructor("team_detail", team.TeamDetail, 8);
registerConstructor("authentication_context", authenticationContext.AuthenticationContext, 3);
registerConstructor("admin_client_shared_state", adminClientSharedState.AdminClientSharedState, 5);
registerConstructor("public_client_shared_state", publicClientSharedState.PublicClientSharedState, 4);

export function ensure_decoders() {
  return true;
}
