//// Generated. Do not edit.
////
//// Root API ToClient dispatch for the public Mount.
////
//// Derived from shared/api/to_client.gleam and client/public/pages.
////
//// Each ToClient constructor maps to client page handlers named by the
//// snake_case of the constructor name (e.g. GamesLoaded -> games_loaded,
//// GameScoreUpdated -> game_score_updated). Handlers receive constructor
//// fields as labeled args and return the local page Msg. A constructor
//// with multiple active handlers fans out to every matching handler.
//// Constructors owned by another Mount fall through to the catch-all.

import client/public/pages/games
import client/public/pages/games/id_ as game_detail
import client/public/pages/standings
import client/public/pages/teams/slug_ as team
import gleam/list
import shared/api/to_client.{type ToClient}

pub type Msg {
  GamesPage(games.Msg)
  GameDetailPage(game_detail.Msg)
  StandingsPage(standings.Msg)
  TeamPage(team.Msg)
}

pub fn to_client(msg: ToClient) -> List(Msg) {
  case msg {
    to_client.GamesLoaded(games: games_list) -> [
      GamesPage(games.games_loaded(games: games_list)),
    ]
    to_client.GameScoreUpdated(update: update) ->
      list.flatten([
        [GamesPage(games.game_score_updated(update: update))],
        [GameDetailPage(game_detail.game_score_updated(update: update))],
        [TeamPage(team.game_score_updated(update: update))],
      ])
    to_client.GamesLoadFailed(reason: reason) ->
      list.flatten([
        [GamesPage(games.games_load_failed(reason: reason))],
        [GameDetailPage(game_detail.games_load_failed(reason: reason))],
        [TeamPage(team.games_load_failed(reason: reason))],
      ])
    to_client.GameLoaded(game: game) -> [
      GameDetailPage(game_detail.game_loaded(game: game)),
    ]
    to_client.StandingsLoaded(rows: rows) -> [
      StandingsPage(standings.standings_loaded(rows: rows)),
    ]
    to_client.PowerRankingsLoaded(rows: rows) -> [
      StandingsPage(standings.power_rankings_loaded(rows: rows)),
    ]
    to_client.StandingsUpdated(rows: rows) -> [
      StandingsPage(standings.standings_updated(rows: rows)),
    ]
    to_client.TeamLoaded(team: team_detail) -> [
      TeamPage(team.team_loaded(team: team_detail)),
    ]
    _ -> []
  }
}
