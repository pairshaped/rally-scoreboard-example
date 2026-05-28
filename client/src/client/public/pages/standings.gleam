//// Client public standings page.
////
//// Owns the page Msg type and constructor-named ToClient handlers for the
//// public standings route. Shared page modules keep target-neutral model,
//// view, and pure helpers.

import shared/api/domain/standing.{type PowerRankingRow, type StandingRow}

pub type Msg {
  LoadedStandings(List(StandingRow))
  LoadedPowerRankings(List(PowerRankingRow))
}

pub fn standings_loaded(rows rows: List(StandingRow)) -> Msg {
  LoadedStandings(rows)
}

pub fn power_rankings_loaded(rows rows: List(PowerRankingRow)) -> Msg {
  LoadedPowerRankings(rows)
}

pub fn standings_updated(rows rows: List(StandingRow)) -> Msg {
  LoadedStandings(rows)
}
