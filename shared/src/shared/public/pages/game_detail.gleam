//// Shared public game-detail page state and rendering.
////
//// The public client owns the page model while server handlers provide game
//// data and score updates through ToClient messages.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import shared/api/domain/game.{type GameDetail, type GameScoreUpdate}
import shared/api/to_client
import shared/components/ui

pub type Msg {
  LoadedGame(GameDetail)
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.GameLoaded(game:) -> Some(LoadedGame(game))
    to_client.GameScoreUpdated(update:) -> Some(UpdatedScore(update))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}

pub fn view_game_detail(
  game: Option(GameDetail),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  case game {
    None -> html.p([attribute.class("muted")], [html.text("Loading game...")])
    Some(game) ->
      html.div([], [
        html.div([attribute.class("game-card")], [
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
          ui.status_badge(game.status),
        ]),
        html.h2([], [html.text("Scoring summary")]),
        html.ul(
          [],
          list.map(game.scoring_summary, fn(item) {
            html.li([], [html.text(item)])
          }),
        ),
      ])
  }
}

pub fn view_game_detail_page(
  game: Option(GameDetail),
  on_navigate_team: fn(String) -> msg,
) -> Element(msg) {
  html.main([], [
    html.section([attribute.class("panel")], [
      ui.section_head(
        "Game detail",
        "Rendered by SSR, hydrated from embedded ETF page data.",
      ),
      view_game_detail(game, on_navigate_team),
    ]),
  ])
}
