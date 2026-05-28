//// Public standings page — view tests.

import gleam/string
import gleeunit/should
import lustre/element
import shared/api/domain/standing.{type StandingRow, StandingRow}
import shared/public/pages/standings

fn on_navigate_team(_slug: String) -> Nil {
  Nil
}

fn render_view(rows: List(StandingRow)) -> String {
  standings.view_standings_page(rows, on_navigate_team)
  |> element.to_readable_string
}

fn make_row(code: String, wins: Int, losses: Int) -> StandingRow {
  StandingRow(
    team_code: code,
    team_name: code <> " Name",
    slug: code,
    wins:,
    losses:,
    points_for: wins * 50,
    points_against: losses * 40,
  )
}

pub fn empty_state_renders_placeholder_test() {
  render_view([])
  |> string.contains("Waiting for standings...")
  |> should.be_true
}

pub fn loaded_standings_render_team_data_test() {
  let html = render_view([make_row("TOR", 10, 2), make_row("NYC", 8, 4)])
  html |> string.contains("TOR") |> should.be_true
  html |> string.contains("TOR Name") |> should.be_true
  html |> string.contains("NYC") |> should.be_true
  html |> string.contains("NYC Name") |> should.be_true
  html |> string.contains("10") |> should.be_true
  html |> string.contains("2") |> should.be_true
  html |> string.contains("8") |> should.be_true
  html |> string.contains("4") |> should.be_true
}

pub fn standings_render_team_links_test() {
  let html = render_view([make_row("TOR", 10, 2)])
  html |> string.contains("href=\"/teams/TOR\"") |> should.be_true
}

pub fn standings_render_points_columns_test() {
  let html = render_view([make_row("TOR", 10, 2)])
  html |> string.contains("500") |> should.be_true
  html |> string.contains("80") |> should.be_true
}

pub fn page_includes_table_header_test() {
  let html = render_view([make_row("TOR", 10, 2)])
  html |> string.contains("Team") |> should.be_true
  html |> string.contains("W") |> should.be_true
  html |> string.contains("L") |> should.be_true
  html |> string.contains("PF") |> should.be_true
  html |> string.contains("PA") |> should.be_true
}
