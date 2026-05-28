//// Client public game-detail page.
////
//// Owns the page Msg type and constructor-named ToClient handlers for the
//// public game-detail route. Shared page modules keep target-neutral model,
//// view, and pure helpers.

import shared/api/domain/game.{type GameDetail, type GameScoreUpdate}

pub type Msg {
  LoadedGame(GameDetail)
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn game_loaded(game game: GameDetail) -> Msg {
  LoadedGame(game)
}

pub fn game_score_updated(update update: GameScoreUpdate) -> Msg {
  UpdatedScore(update)
}

pub fn games_load_failed(reason reason: String) -> Msg {
  LoadFailed(reason)
}
