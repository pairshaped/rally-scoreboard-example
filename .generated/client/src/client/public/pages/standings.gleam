//// Client public standings page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public standings route. Shared page modules keep target-neutral view code.

import gleam/list
import lustre/effect.{type Effect}
import shared/api/domain/standing.{
  type PowerRankingRow, type StandingRow, StandingRow,
}

pub type Model {
  Model(rows: List(StandingRow), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(rows: [], notice: "")
}

// nolint: redundant_case -- Single-branch case is future-proof for browser events.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn standings_loaded(
  model model: Model,
  rows rows: List(StandingRow),
) -> #(Model, Effect(Msg)) {
  #(Model(..model, rows:), effect.none())
}

pub fn power_rankings_loaded(
  model model: Model,
  rows rows: List(PowerRankingRow),
) -> #(Model, Effect(Msg)) {
  #(Model(..model, rows: power_rankings_to_standings(rows)), effect.none())
}

fn power_rankings_to_standings(
  rows: List(PowerRankingRow),
) -> List(StandingRow) {
  list.map(rows, fn(row) {
    StandingRow(
      team_code: row.team_code,
      team_name: row.team_name,
      slug: row.slug,
      wins: row.wins,
      losses: row.losses,
      points_for: row.points_for,
      points_against: row.points_against,
    )
  })
}
