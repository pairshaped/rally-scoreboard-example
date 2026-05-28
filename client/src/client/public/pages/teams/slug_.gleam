//// Client public team page.
////
//// Owns the page Msg type and constructor-named ToClient handlers for the
//// public team route. Shared page modules keep target-neutral model, view,
//// and pure helpers including apply_score_update.

import shared/api/domain/game.{type GameScoreUpdate}
import shared/api/domain/team.{type TeamDetail}

pub type Msg {
  LoadedTeam(team: TeamDetail)
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn team_loaded(team team: TeamDetail) -> Msg {
  LoadedTeam(team:)
}

pub fn game_score_updated(update update: GameScoreUpdate) -> Msg {
  UpdatedScore(update)
}

pub fn games_load_failed(reason reason: String) -> Msg {
  LoadFailed(reason)
}
