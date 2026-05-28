//// Shared public standings page state and rendering.
////
//// The page can display official standings and power rankings, both supplied
//// through root API ToClient messages.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/api/domain/standing.{type PowerRankingRow, type StandingRow}
import shared/api/to_client
import shared/components/ui

pub type Msg {
  LoadedStandings(List(StandingRow))
  LoadedPowerRankings(List(PowerRankingRow))
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.StandingsLoaded(rows:) -> Some(LoadedStandings(rows))
    to_client.PowerRankingsLoaded(rows:) -> Some(LoadedPowerRankings(rows))
    to_client.StandingsUpdated(rows:) -> Some(LoadedStandings(rows))
    _ -> None
  }
}

pub fn view_standings(
  rows: List(StandingRow),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  case rows {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for standings...")])
    _ ->
      html.table([attribute.class("standings-table")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("Team")]),
            html.th([], [html.text("W")]),
            html.th([], [html.text("L")]),
            html.th([], [html.text("PF")]),
            html.th([], [html.text("PA")]),
          ]),
        ]),
        html.tbody(
          [],
          list.map(rows, fn(row) { view_standing_row(row, on_navigate_team) }),
        ),
      ])
  }
}

fn view_standing_row(
  row: StandingRow,
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  html.tr([], [
    html.td([], [
      html.a(
        [
          attribute.href("/teams/" <> row.slug),
          event.on_click(on_navigate_team(row.slug))
            |> event.prevent_default,
        ],
        [
          html.strong([], [html.text(row.team_code)]),
          html.text(" " <> row.team_name),
        ],
      ),
    ]),
    html.td([], [html.text(int.to_string(row.wins))]),
    html.td([], [html.text(int.to_string(row.losses))]),
    html.td([], [html.text(int.to_string(row.points_for))]),
    html.td([], [html.text(int.to_string(row.points_against))]),
  ])
}

pub fn view_standings_page(
  rows: List(StandingRow),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  html.main([], [
    html.section([attribute.class("panel")], [
      ui.section_head("League table", ""),
      view_standings(rows, on_navigate_team),
    ]),
  ])
}
