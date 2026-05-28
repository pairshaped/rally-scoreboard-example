//// Public team detail page — view tests.

import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import lustre/element
import shared/api/domain/game.{
  Final, GameScoreUpdate, Live, PublicGameSummary, Team,
}
import shared/api/domain/team.{type TeamDetail, TeamDetail}
import shared/public/pages/teams/slug_ as team_page

fn on_navigate_team(_slug: String) -> Nil {
  Nil
}

fn on_navigate_game(_id: Int) -> Nil {
  Nil
}

fn render_view(m: option.Option(team_page.Model)) -> String {
  team_page.view_team_page(m, on_navigate_team, on_navigate_game)
  |> element.to_readable_string
}

fn make_detail() -> TeamDetail {
  TeamDetail(
    code: "TOR",
    name: "Toronto",
    slug: "tor",
    wins: 12,
    losses: 3,
    points_for: 600,
    points_against: 450,
    recent_games: [],
  )
}

pub fn empty_state_renders_loading_text_test() {
  render_view(None)
  |> string.contains("Loading team...")
  |> should.be_true
}

pub fn loaded_team_renders_name_and_code_test() {
  let html = render_view(Some(team_page.Model(team: make_detail())))
  html |> string.contains("Toronto") |> should.be_true
  html |> string.contains("TOR") |> should.be_true
}

pub fn loaded_team_renders_record_and_stats_test() {
  let html = render_view(Some(team_page.Model(team: make_detail())))
  html |> string.contains("W-L") |> should.be_true
  html |> string.contains("12-3") |> should.be_true
  html |> string.contains("PF") |> should.be_true
  html |> string.contains("600") |> should.be_true
  html |> string.contains("PA") |> should.be_true
  html |> string.contains("450") |> should.be_true
}

pub fn loaded_team_shows_recent_games_header_test() {
  render_view(Some(team_page.Model(team: make_detail())))
  |> string.contains("Recent games")
  |> should.be_true
}

pub fn empty_recent_games_renders_placeholder_test() {
  render_view(Some(team_page.Model(team: make_detail())))
  |> string.contains("No games yet.")
  |> should.be_true
}

pub fn recent_games_render_test() {
  let detail =
    TeamDetail(..make_detail(), recent_games: [
      PublicGameSummary(
        id: 1,
        home: Team(code: "TOR", name: "Toronto", slug: "tor"),
        away: Team(code: "NYC", name: "New York", slug: "nyc"),
        home_score: 85,
        away_score: 72,
        status: Final,
      ),
    ])
  let html = render_view(Some(team_page.Model(team: detail)))
  html |> string.contains("Toronto") |> should.be_true
  html |> string.contains("New York") |> should.be_true
  html |> string.contains("85") |> should.be_true
  html |> string.contains("72") |> should.be_true
  html |> string.contains("Final") |> should.be_true
  html |> string.contains("href=\"/games/1\"") |> should.be_true
}

pub fn score_update_changes_recent_game_test() {
  let detail =
    TeamDetail(..make_detail(), recent_games: [
      PublicGameSummary(
        id: 1,
        home: Team(code: "TOR", name: "Toronto", slug: "tor"),
        away: Team(code: "NYC", name: "New York", slug: "nyc"),
        home_score: 1,
        away_score: 2,
        status: Live("4th"),
      ),
    ])
  let updated =
    team_page.apply_score_update(
      team_page.Model(team: detail),
      GameScoreUpdate(
        game_id: 1,
        home_score: 3,
        away_score: 4,
        period: "4th",
        status: Live("4th"),
      ),
    )
  let html = render_view(Some(updated))
  html |> string.contains("3") |> should.be_true
  html |> string.contains("4") |> should.be_true
}

pub fn final_score_update_changes_record_and_points_test() {
  let detail =
    TeamDetail(
      code: "MTL",
      name: "Montreal",
      slug: "mtl",
      wins: 0,
      losses: 0,
      points_for: 0,
      points_against: 0,
      recent_games: [
        PublicGameSummary(
          id: 1,
          home: Team(code: "TOR", name: "Toronto", slug: "tor"),
          away: Team(code: "MTL", name: "Montreal", slug: "mtl"),
          home_score: 4,
          away_score: 4,
          status: Live("4th"),
        ),
      ],
    )
  let updated =
    team_page.apply_score_update(
      team_page.Model(team: detail),
      GameScoreUpdate(
        game_id: 1,
        home_score: 4,
        away_score: 5,
        period: "Final",
        status: Final,
      ),
    )
  updated.team.wins |> should.equal(1)
  updated.team.losses |> should.equal(0)
  updated.team.points_for |> should.equal(5)
  updated.team.points_against |> should.equal(4)
}
