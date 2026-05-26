//// Shared public standings page state and rendering.
////
//// The page can display official standings and power rankings, both supplied
//// through root API ToClient messages.

import gleam/option.{type Option, None, Some}
import shared/api/domain/standing.{type PowerRankingRow, type StandingRow}
import shared/api/to_client

pub type Msg {
  LoadedStandings(List(StandingRow))
  LoadedPowerRankings(List(PowerRankingRow))
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.StandingsLoaded(rows:) -> Some(LoadedStandings(rows))
    to_client.PowerRankingsLoaded(rows:) -> Some(LoadedPowerRankings(rows))
    to_client.StandingsUpdated(rows:) -> Some(LoadedStandings(rows))
    _ -> None
  }
}
