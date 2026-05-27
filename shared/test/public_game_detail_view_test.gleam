//// Public game detail page — view tests.

import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import lustre/element
import shared/api/domain/game.{
  type GameDetail, Final, GameDetail, GameScoreUpdate, Live, Team,
}
import shared/api/to_client
import shared/public/pages/game_detail

fn on_navigate_team(_slug: String) -> Nil {
  Nil
}

fn render_view(game: option.Option(GameDetail)) -> String {
  game_detail.view_game_detail_page(game, on_navigate_team)
  |> element.to_readable_string
}

fn make_detail() -> GameDetail {
  GameDetail(
    id: 1,
    home: Team(code: "TOR", name: "Toronto", slug: "tor"),
    away: Team(code: "NYC", name: "New York", slug: "nyc"),
    home_score: 85,
    away_score: 72,
    status: Final,
    scoring_summary: ["TOR scored first", "NYC answered late"],
  )
}

pub fn empty_state_renders_loading_text_test() {
  render_view(None)
  |> string.contains("Loading game...")
  |> should.be_true
}

pub fn loaded_game_renders_team_names_and_scores_test() {
  let html = render_view(Some(make_detail()))
  html |> string.contains("Toronto") |> should.be_true
  html |> string.contains("New York") |> should.be_true
  html |> string.contains("85") |> should.be_true
  html |> string.contains("72") |> should.be_true
}

pub fn loaded_game_renders_status_test() {
  render_view(Some(make_detail()))
  |> string.contains("Final")
  |> should.be_true
}

pub fn loaded_game_renders_scoring_summary_test() {
  let html = render_view(Some(make_detail()))
  html |> string.contains("Scoring summary") |> should.be_true
  html |> string.contains("TOR scored first") |> should.be_true
  html |> string.contains("NYC answered late") |> should.be_true
}

pub fn loaded_game_renders_team_links_test() {
  let html = render_view(Some(make_detail()))
  html |> string.contains("href=\"/teams/tor\"") |> should.be_true
  html |> string.contains("href=\"/teams/nyc\"") |> should.be_true
}

pub fn live_status_renders_period_test() {
  let game = GameDetail(..make_detail(), status: Live("2H"))
  render_view(Some(game))
  |> string.contains("2H")
  |> should.be_true
}

// --- receive mapping tests ---

pub fn game_detail_receive_maps_loaded_to_msg_test() {
  let detail = make_detail()
  game_detail.receive(to_client.GameLoaded(game: detail))
  |> should.equal(Some(game_detail.LoadedGame(detail)))
}

pub fn game_detail_receive_maps_score_update_to_msg_test() {
  let update =
    GameScoreUpdate(
      game_id: 1,
      home_score: 90,
      away_score: 75,
      period: "Q3",
      status: Live("Q3"),
    )
  game_detail.receive(to_client.GameScoreUpdated(update:))
  |> should.equal(Some(game_detail.UpdatedScore(update)))
}

pub fn game_detail_receive_returns_none_for_unknown_test() {
  game_detail.receive(to_client.StandingsLoaded(rows: []))
  |> should.equal(None)
}
