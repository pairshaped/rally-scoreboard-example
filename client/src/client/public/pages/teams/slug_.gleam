//// Client public team page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public team route. Shared page modules keep target-neutral view
//// code and pure model helpers.

import gleam/option.{type Option, None, Some}
import lustre/effect.{type Effect}
import shared/api/domain/game.{type GameScoreUpdate}
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

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn team_loaded(
  model _model: Model,
  team team: TeamDetail,
) -> #(Model, Effect(Msg)) {
  #(
    Model(team: Some(shared_team_page.Model(team:)), notice: ""),
    effect.none(),
  )
}

pub fn game_score_updated(
  model model: Model,
  update update: GameScoreUpdate,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      team: option.map(model.team, fn(team_model) {
        shared_team_page.apply_score_update(team_model, update)
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
