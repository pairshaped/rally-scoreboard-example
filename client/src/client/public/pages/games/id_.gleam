//// Client public game-detail page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public game-detail route. Shared page modules keep target-neutral
//// view code.

import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared/api/domain/game.{type GameDetail, type GameSnapshot, GameDetail}

pub type Model {
  Model(game: Option(GameDetail), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(game: None, notice: "")
}

// nolint: label_possible, redundant_case -- model/msg is the standard TEA signature. Single-branch case is future-proof for browser events.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn game_loaded(
  model _model: Model,
  game game: GameDetail,
) -> #(Model, Effect(Msg)) {
  #(Model(game: Some(game), notice: ""), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, game: update_selected_game(model.game, game)), effect.none())
}

pub fn games_load_failed(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}

fn update_selected_game(
  game: Option(GameDetail),
  snapshot: GameSnapshot,
) -> Option(GameDetail) {
  case game {
    Some(game) if game.id == snapshot.id ->
      Some(
        GameDetail(
          ..game,
          home_score: snapshot.home_score,
          away_score: snapshot.away_score,
          status: snapshot.status,
        ),
      )
    _ -> game
  }
}
