//// Client-side contract tests for the Scoreboard example.
////
//// These tests keep the hand-written receiver hub and generated receiver
//// dispatch aligned while Rally generation is being rebuilt toward this app.

import client/public/receivers
import generated/public/receiver_dispatch
import gleeunit
import gleeunit/should
import shared/api/domain/game
import shared/api/to_client
import shared/public/pages/game_detail as game_detail_page
import shared/public/pages/games as games_page

pub fn main() {
  gleeunit.main()
}

pub fn public_to_client_receiver_dispatch_fans_out_to_all_interested_pages_test() {
  let update =
    game.GameScoreUpdate(
      game_id: 2,
      home_score: 101,
      away_score: 99,
      period: "Q4",
      status: game.Live("Q4"),
    )

  let messages =
    receiver_dispatch.to_client(to_client.GameScoreUpdated(update:))

  messages
  |> should.equal([
    receivers.GamesPage(games_page.UpdatedScore(update)),
    receivers.GameDetailPage(game_detail_page.UpdatedScore(update)),
  ])
}
