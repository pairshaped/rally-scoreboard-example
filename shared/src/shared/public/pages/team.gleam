//// Public team detail page.
////
//// Drives the page-local model and message types for the team detail view.
//// The server handler loads the team by slug; the client renders after
//// the TeamLoaded ToClient push arrives.

import gleam/option.{type Option, None, Some}
import shared/api/domain/team.{type TeamDetail}
import shared/api/to_client

pub type Model {
  Model(team: TeamDetail)
}

pub type Msg {
  LoadedTeam(team: TeamDetail)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.TeamLoaded(team:) -> Some(LoadedTeam(team:))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}
