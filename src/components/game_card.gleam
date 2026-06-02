import api/domain/game.{type PublicGameSummary}
import components/ui
import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn public_summary(
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
