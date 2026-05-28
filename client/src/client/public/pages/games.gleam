//// Client public games-list page.
////
//// Owns the page Msg type and constructor-named ToClient handlers for the
//// public games route. Shared page modules keep target-neutral model, view,
//// and pure helpers.

import shared/api/domain/game.{type GameScoreUpdate, type PublicGameSummary}

pub type Msg {
  LoadedGames(List(PublicGameSummary))
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn games_loaded(games games: List(PublicGameSummary)) -> Msg {
  LoadedGames(games)
}

pub fn game_score_updated(update update: GameScoreUpdate) -> Msg {
  UpdatedScore(update)
}

pub fn games_load_failed(reason reason: String) -> Msg {
  LoadFailed(reason)
}
