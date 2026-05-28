//// Client public games-list page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public games route. Shared page modules keep target-neutral view code.

import gleam/list
import lustre/effect.{type Effect}
import shared/api/domain/game.{
  type GameScoreUpdate, type PublicGameSummary, PublicGameSummary,
}

pub type Model {
  Model(games: List(PublicGameSummary), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(games: [], notice: "")
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn games_loaded(
  model _model: Model,
  games games: List(PublicGameSummary),
) -> #(Model, Effect(Msg)) {
  #(Model(games:, notice: ""), effect.none())
}

pub fn game_score_updated(
  model model: Model,
  update update: GameScoreUpdate,
) -> #(Model, Effect(Msg)) {
  #(
    Model(..model, games: update_games(model.games, update)),
    effect.none(),
  )
}

pub fn games_load_failed(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}

fn update_games(
  games: List(PublicGameSummary),
  update: GameScoreUpdate,
) -> List(PublicGameSummary) {
  list.map(games, fn(game) {
    case game.id == update.game_id {
      True ->
        PublicGameSummary(
          ..game,
          home_score: update.home_score,
          away_score: update.away_score,
          status: update.status,
        )
      False -> game
    }
  })
}
