//// Admin ToClient receiver hub.
////
//// The generated admin receiver dispatch delegates here so hand-written
//// client code decides which admin page modules are interested in each
//// server-emitted message.

import gleam/option.{None, Some}
import shared/admin/pages/games
import shared/api/to_client

pub type Msg {
  GamesPage(games.Msg)
}

pub fn receive_active(event: to_client.ToClient) -> List(Msg) {
  case games.receive(event) {
    Some(msg) -> [GamesPage(msg)]
    None -> []
  }
}
