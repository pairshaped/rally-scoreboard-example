//// Client admin games page.
////
//// Owns the page Msg type and constructor-named ToClient handlers for the
//// admin games route. Shared page modules keep target-neutral model, view,
//// and pure helpers.

import shared/api/domain/game.{
  type AdminGameDetail, type AdminGameSummary, type GameScoreUpdate,
}

pub type Msg {
  LoadedGames(List(AdminGameSummary))
  CreatedGame(AdminGameDetail)
  SavedGame(AdminGameDetail)
  ScoreUpdated(GameScoreUpdate)
  Failed(String)
}

pub fn admin_games_loaded(games games: List(AdminGameSummary)) -> Msg {
  LoadedGames(games)
}

pub fn game_created(game game: AdminGameDetail) -> Msg {
  CreatedGame(game)
}

pub fn score_update_saved(game game: AdminGameDetail) -> Msg {
  SavedGame(game)
}

pub fn result_saved(game game: AdminGameDetail) -> Msg {
  SavedGame(game)
}

pub fn game_score_updated(update update: GameScoreUpdate) -> Msg {
  ScoreUpdated(update)
}

pub fn admin_error(reason reason: String) -> Msg {
  Failed(reason)
}
