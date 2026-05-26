//// Shared public games-list page state and rendering.
////
//// This page receives list loads and broad score updates, then keeps visible
//// game summaries in sync without a full page reload.

import gleam/option.{type Option, None, Some}
import shared/api/domain/game.{type GameScoreUpdate, type PublicGameSummary}
import shared/api/to_client

pub type Msg {
  LoadedGames(List(PublicGameSummary))
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.GamesLoaded(games:) -> Some(LoadedGames(games))
    to_client.GameScoreUpdated(update:) -> Some(UpdatedScore(update))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}
