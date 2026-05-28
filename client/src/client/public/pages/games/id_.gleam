//// Client public game-detail page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public game-detail route. Shared page modules keep target-neutral
//// view code.

import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared/api/domain/game.{type GameDetail, type GameScoreUpdate, GameDetail}

pub type Model {
  Model(game: Option(GameDetail), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(game: None, notice: "")
}

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

pub fn game_score_updated(
  model model: Model,
  update update: GameScoreUpdate,
) -> #(Model, Effect(Msg)) {
  #(
    Model(..model, game: update_selected_game(model.game, update)),
    effect.none(),
  )
}

pub fn games_load_failed(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}

fn update_selected_game(
  game: Option(GameDetail),
  update: GameScoreUpdate,
) -> Option(GameDetail) {
  case game {
    Some(game) if game.id == update.game_id ->
      Some(
        GameDetail(
          ..game,
          home_score: update.home_score,
          away_score: update.away_score,
          status: update.status,
        ),
      )
    _ -> game
  }
}
