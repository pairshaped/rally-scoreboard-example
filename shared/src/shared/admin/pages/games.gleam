//// Shared admin games page state and rendering.
////
//// The admin client uses this page to create games, edit live scores, mark
//// finals, and reflect server-confirmed updates.

import gleam/int
import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/api/domain/game.{type AdminGameSummary, Final}
import shared/components/ui

pub fn view_games(
  games: List(AdminGameSummary),
  on_adjust_away: fn(Int, Int, Int, Int) -> msg,
  on_adjust_home: fn(Int, Int, Int, Int) -> msg,
  on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  case games {
    [] -> html.p([attribute.class("muted")], [html.text("No games yet.")])
    _ ->
      html.div(
        [attribute.class("game-grid")],
        list.map(games, fn(game) {
          view_game_card(game, on_adjust_away, on_adjust_home, on_mark_final)
        }),
      )
  }
}

fn view_game_card(
  game: AdminGameSummary,
  on_adjust_away: fn(Int, Int, Int, Int) -> msg,
  on_adjust_home: fn(Int, Int, Int, Int) -> msg,
  on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  html.article([attribute.class("game-card")], [
    html.div([attribute.class("admin-score-row")], [
      html.strong([], [html.text(game.away_code)]),
      score_button(
        "-",
        on_adjust_away(game.id, game.home_score, game.away_score, -1),
      ),
      score_button(
        "+",
        on_adjust_away(game.id, game.home_score, game.away_score, 1),
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.away_score)),
      ]),
    ]),
    html.div([attribute.class("admin-score-row")], [
      html.strong([], [html.text(game.home_code)]),
      score_button(
        "-",
        on_adjust_home(game.id, game.home_score, game.away_score, -1),
      ),
      score_button(
        "+",
        on_adjust_home(game.id, game.home_score, game.away_score, 1),
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.home_score)),
      ]),
    ]),
    html.div([attribute.class("score-line admin-status-row")], [
      ui.status_badge(game.status),
      final_action(game, on_mark_final),
    ]),
  ])
}

fn score_button(label: String, msg: msg) -> Element(msg) {
  html.button([attribute.class("small score-control"), event.on_click(msg)], [
    html.text(label),
  ])
}

fn final_action(
  game: AdminGameSummary,
  on_mark_final: fn(Int) -> msg,
) -> Element(msg) {
  case game.status {
    Final -> html.span([], [])
    _ ->
      html.button(
        [
          attribute.class("small secondary"),
          event.on_click(on_mark_final(game.id)),
        ],
        [html.text("Finalize")],
      )
  }
}
