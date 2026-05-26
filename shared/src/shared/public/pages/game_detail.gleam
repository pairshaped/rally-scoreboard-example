//// Shared public game-detail page state and rendering.
////
//// The public client owns the page model while server handlers provide game
//// data and score updates through ToClient messages.

import gleam/option.{type Option, None, Some}
import shared/api/domain/game.{type GameDetail, type GameScoreUpdate}
import shared/api/to_client

pub type Msg {
  LoadedGame(GameDetail)
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.GameLoaded(game:) -> Some(LoadedGame(game))
    to_client.GameScoreUpdated(update:) -> Some(UpdatedScore(update))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}
