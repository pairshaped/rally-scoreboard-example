//// Public games page — view tests.

import gleam/string
import gleeunit/should
import lustre/element
import shared/api/domain/game.{
  type PublicGameSummary, Final, Live, PublicGameSummary, Scheduled, Team,
}
import shared/public/pages/games

fn on_navigate_team(_slug: String) -> Nil {
  Nil
}

fn on_navigate_game(_id: Int) -> Nil {
  Nil
}

fn render_view(games_list: List(PublicGameSummary)) -> String {
  games.view(games_list, on_navigate_team, on_navigate_game)
  |> element.to_readable_string
}

fn make_game(
  id: Int,
  home: String,
  away: String,
  h: Int,
  a: Int,
) -> PublicGameSummary {
  PublicGameSummary(
    id:,
    home: Team(code: home, name: "Home " <> home, slug: home),
    away: Team(code: away, name: "Away " <> away, slug: away),
    home_score: h,
    away_score: a,
    status: Live("Q2"),
  )
}

pub fn empty_state_renders_placeholder_test() {
  render_view([])
  |> string.contains("Waiting for scores...")
  |> should.be_true
}

pub fn loaded_games_render_team_names_and_scores_test() {
  let html =
    render_view([
      make_game(1, "TOR", "NYC", 85, 72),
      make_game(2, "BOS", "LAK", 64, 58),
    ])
  html |> string.contains("Home TOR") |> should.be_true
  html |> string.contains("Away NYC") |> should.be_true
  html |> string.contains("85") |> should.be_true
  html |> string.contains("72") |> should.be_true
  html |> string.contains("Home BOS") |> should.be_true
  html |> string.contains("Away LAK") |> should.be_true
}

pub fn game_cards_render_details_links_test() {
  render_view([make_game(1, "TOR", "NYC", 85, 72)])
  |> string.contains("Details")
  |> should.be_true
}

pub fn game_cards_render_hrefs_test() {
  let html = render_view([make_game(7, "TOR", "NYC", 85, 72)])
  html |> string.contains("href=\"/games/7\"") |> should.be_true
  html |> string.contains("href=\"/teams/TOR\"") |> should.be_true
  html |> string.contains("href=\"/teams/NYC\"") |> should.be_true
}

pub fn status_badges_render_test() {
  let scheduled =
    PublicGameSummary(
      id: 1,
      home: Team(code: "A", name: "HA", slug: "a"),
      away: Team(code: "B", name: "AB", slug: "b"),
      home_score: 0,
      away_score: 0,
      status: Scheduled,
    )
  let live = PublicGameSummary(..scheduled, id: 2, status: Live("OT"))
  let final = PublicGameSummary(..scheduled, id: 3, status: Final)
  let html = render_view([scheduled, live, final])
  html |> string.contains("Scheduled") |> should.be_true
  html |> string.contains("OT") |> should.be_true
  html |> string.contains("Final") |> should.be_true
}

pub fn page_includes_section_header_test() {
  render_view([])
  |> string.contains("Today")
  |> should.be_true
}
