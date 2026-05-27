//// Public team detail page.
////
//// Drives the page-local model and message types for the team detail view.
//// The server handler loads the team by slug; the client renders after
//// the TeamLoaded ToClient push arrives.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import shared/api/domain/team.{type TeamDetail, TeamDetail}
import shared/api/to_client
import shared/components/ui
import shared/public/pages/games as public_games

pub type Model {
  Model(team: TeamDetail)
}

pub type Msg {
  LoadedTeam(team: TeamDetail)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.TeamLoaded(team:) -> Some(LoadedTeam(team:))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}

pub fn view_team_detail(
  team: Option(Model),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  case team {
    None -> html.p([attribute.class("muted")], [html.text("Loading team...")])
    Some(Model(team: detail)) -> {
      let TeamDetail(
        code:,
        name:,
        slug: _,
        wins:,
        losses:,
        points_for:,
        points_against:,
        recent_games:,
      ) = detail
      html.div([], [
        html.section([attribute.class("panel")], [
          ui.section_head(name, "Team details loaded by slug."),
          html.div([attribute.class("stat-card")], [
            html.div([], [
              html.strong([], [html.text(code)]),
              html.text(" · " <> name),
            ]),
            html.div([attribute.class("score-line")], [
              html.span([], [
                html.text(
                  "W-L: " <> int.to_string(wins) <> "-" <> int.to_string(losses),
                ),
              ]),
              html.span([], [html.text("PF: " <> int.to_string(points_for))]),
              html.span([], [html.text("PA: " <> int.to_string(points_against))]),
            ]),
          ]),
        ]),
        html.section([attribute.class("panel")], [
          ui.section_head("Recent games", ""),
          case recent_games {
            [] ->
              html.p([attribute.class("muted")], [html.text("No games yet.")])
            _ ->
              html.div(
                [attribute.class("game-grid")],
                list.map(recent_games, fn(game) {
                  public_games.view_game_card(
                    game,
                    on_navigate_team,
                    on_navigate_game,
                  )
                }),
              )
          },
        ]),
      ])
    }
  }
}

pub fn view_team_page(
  team: Option(Model),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.main([], [view_team_detail(team, on_navigate_team, on_navigate_game)])
}
