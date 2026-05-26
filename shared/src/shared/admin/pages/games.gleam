//// Shared admin games page state and rendering.
////
//// The admin client uses this page to create games, edit live scores, mark
//// finals, and reflect server-confirmed updates.

import gleam/option.{type Option, None, Some}
import shared/api/domain/game.{type AdminGameDetail, type AdminGameSummary}
import shared/api/to_client

pub type Msg {
  LoadedGames(List(AdminGameSummary))
  CreatedGame(AdminGameDetail)
  SavedGame(AdminGameDetail)
  Failed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.AdminGamesLoaded(games:) -> Some(LoadedGames(games))
    to_client.GameCreated(game:) -> Some(CreatedGame(game))
    to_client.ScoreUpdateSaved(game:) -> Some(SavedGame(game))
    to_client.ResultSaved(game:) -> Some(SavedGame(game))
    to_client.AdminError(reason:) -> Some(Failed(reason))
    _ -> None
  }
}
