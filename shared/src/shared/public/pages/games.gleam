//// Shared public games-list page state and rendering.
////
//// This page receives list loads and broad score updates, then keeps visible
//// game summaries in sync without a full page reload.

import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/api/domain/game.{type PublicGameSummary}
import shared/components/ui

pub fn view_game_grid(
  games: List(PublicGameSummary),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  case games {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for scores...")])
    _ ->
      html.div(
        [attribute.class("game-grid")],
        list.map(games, fn(game) {
          view_game_card(game, on_navigate_team, on_navigate_game)
        }),
      )
  }
}

pub fn view_game_card(
  game: PublicGameSummary,
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.article([attribute.class("game-card")], [
    html.div([attribute.class("team-row")], [
      html.a(
        [
          attribute.href("/teams/" <> game.away.slug),
          event.on_click(on_navigate_team(game.away.slug))
            |> event.prevent_default,
        ],
        [html.strong([], [html.text(game.away.name)])],
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.away_score)),
      ]),
    ]),
    html.div([attribute.class("team-row")], [
      html.a(
        [
          attribute.href("/teams/" <> game.home.slug),
          event.on_click(on_navigate_team(game.home.slug))
            |> event.prevent_default,
        ],
        [html.strong([], [html.text(game.home.name)])],
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.home_score)),
      ]),
    ]),
    html.div([attribute.class("score-line")], [
      ui.status_badge(game.status),
      html.a(
        [
          attribute.href("/games/" <> int.to_string(game.id)),
          event.on_click(on_navigate_game(game.id))
            |> event.prevent_default,
        ],
        [html.text("Details")],
      ),
    ]),
  ])
}

pub fn view_games_page(
  games: List(PublicGameSummary),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.main([], [
    html.section([attribute.class("panel")], [
      ui.section_head("Today", ""),
      view_game_grid(games, on_navigate_team, on_navigate_game),
    ]),
  ])
}
