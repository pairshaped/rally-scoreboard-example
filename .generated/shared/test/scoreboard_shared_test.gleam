//// Shared package smoke tests.
////
//// These tests keep the shared API package compiling on its own, separate
//// from the client and server packages that import it.

import gleeunit
import gleeunit/should
import shared/api/domain/game
import shared/api/domain/team
import shared/api/to_client
import shared/api/to_server

pub fn main() {
  gleeunit.main()
}

pub fn public_to_server_contract_compiles_test() {
  to_server.LoadGames
  |> should.equal(to_server.LoadGames)
}

pub fn to_client_constructors_exist_and_can_be_constructed_test() {
  let _games_loaded = to_client.GamesLoaded(games: [])
  let _game_updated =
    to_client.GameUpdated(game: game.GameSnapshot(
      id: 1,
      home: game.Team(code: "TOR", name: "Toronto", slug: "tor"),
      away: game.Team(code: "NYC", name: "New York", slug: "nyc"),
      home_score: 10,
      away_score: 5,
      status: game.Live("Q1"),
    ))
  let _standings = to_client.StandingsLoaded(rows: [])
  let _power = to_client.PowerRankingsLoaded(rows: [])
  let _team =
    to_client.TeamLoaded(
      team: team.TeamDetail(
        code: "",
        name: "",
        slug: "",
        wins: 0,
        losses: 0,
        points_for: 0,
        points_against: 0,
        recent_games: [],
      ),
    )

  to_server.LoadGames
  |> should.equal(to_server.LoadGames)
}
