//// Client public team page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public team route. Shared page modules keep target-neutral view
//// code and pure model helpers.

import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared/api/domain/game.{type GameSnapshot}
import shared/api/domain/team.{type TeamDetail}
import shared/public/pages/teams/slug_ as shared_team_page

pub type Model {
  Model(team: Option(shared_team_page.Model), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(team: None, notice: "")
}

// nolint: label_possible, redundant_case -- model/msg is the standard TEA signature. Single-branch case is future-proof for browser events.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn team_loaded(
  model _model: Model,
  team team: TeamDetail,
) -> #(Model, Effect(Msg)) {
  #(Model(team: Some(shared_team_page.Model(team:)), notice: ""), effect.none())
}

pub fn game_created(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      team: option.map(model.team, fn(team_model) {
        shared_team_page.apply_game_created(team_model, game)
      }),
    ),
    effect.none(),
  )
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      team: option.map(model.team, fn(team_model) {
        shared_team_page.apply_game_updated(team_model, game)
      }),
    ),
    effect.none(),
  )
}

pub fn games_load_failed(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}
