//// Public ToClient receiver hub.
////
//// The generated public receiver dispatch delegates here so multiple public
//// pages can react to the same server-emitted message without transport code
//// knowing about page state.

import gleam/list
import gleam/option.{None, Some}
import shared/api/to_client
import shared/public/pages/game_detail
import shared/public/pages/games
import shared/public/pages/standings
import shared/public/pages/team

pub type Msg {
  GamesPage(games.Msg)
  GameDetailPage(game_detail.Msg)
  StandingsPage(standings.Msg)
  TeamPage(team.Msg)
}

fn receive_for_games(event: to_client.ToClient) -> List(Msg) {
  case games.receive(event) {
    Some(msg) -> [GamesPage(msg)]
    None -> []
  }
}

fn receive_for_game_detail(event: to_client.ToClient) -> List(Msg) {
  case game_detail.receive(event) {
    Some(msg) -> [GameDetailPage(msg)]
    None -> []
  }
}

fn receive_for_standings(event: to_client.ToClient) -> List(Msg) {
  case standings.receive(event) {
    Some(msg) -> [StandingsPage(msg)]
    None -> []
  }
}

fn receive_for_team(event: to_client.ToClient) -> List(Msg) {
  case team.receive(event) {
    Some(msg) -> [TeamPage(msg)]
    None -> []
  }
}

pub fn receive_active(event: to_client.ToClient) -> List(Msg) {
  receive_for_games(event)
  |> list.append(receive_for_game_detail(event))
  |> list.append(receive_for_standings(event))
  |> list.append(receive_for_team(event))
}
