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
import shared/api/domain/game.{
  type GameScoreUpdate, type PublicGameSummary, Final, PublicGameSummary,
}
import shared/api/domain/team.{type TeamDetail, TeamDetail}
import shared/api/to_client
import shared/components/ui
import shared/public/pages/games as public_games

pub type Model {
  Model(team: TeamDetail)
}

pub type Msg {
  LoadedTeam(team: TeamDetail)
  UpdatedScore(GameScoreUpdate)
  LoadFailed(String)
}

pub fn receive(event: to_client.ToClient) -> Option(Msg) {
  case event {
    to_client.TeamLoaded(team:) -> Some(LoadedTeam(team:))
    to_client.GameScoreUpdated(update:) -> Some(UpdatedScore(update))
    to_client.GamesLoadFailed(reason:) -> Some(LoadFailed(reason))
    _ -> None
  }
}

pub fn apply_score_update(model: Model, update: GameScoreUpdate) -> Model {
  Model(team: apply_team_score_update(model.team, update))
}

fn apply_team_score_update(
  team: TeamDetail,
  update: GameScoreUpdate,
) -> TeamDetail {
  case list.find(team.recent_games, fn(game) { game.id == update.game_id }) {
    Error(Nil) -> team
    Ok(existing) -> {
      let updated_games =
        list.map(team.recent_games, fn(game) {
          case game.id == update.game_id {
            True -> update_game_summary(game, update)
            False -> game
          }
        })
      let #(old_wins, old_losses, old_for, old_against) =
        record_contribution(team.code, existing)
      let #(new_wins, new_losses, new_for, new_against) =
        record_contribution(team.code, update_game_summary(existing, update))

      TeamDetail(
        ..team,
        wins: team.wins - old_wins + new_wins,
        losses: team.losses - old_losses + new_losses,
        points_for: team.points_for - old_for + new_for,
        points_against: team.points_against - old_against + new_against,
        recent_games: updated_games,
      )
    }
  }
}

fn update_game_summary(
  game: PublicGameSummary,
  update: GameScoreUpdate,
) -> PublicGameSummary {
  PublicGameSummary(
    ..game,
    home_score: update.home_score,
    away_score: update.away_score,
    status: update.status,
  )
}

fn record_contribution(
  team_code: String,
  game: PublicGameSummary,
) -> #(Int, Int, Int, Int) {
  case game.status {
    Final ->
      case game.home.code == team_code, game.away.code == team_code {
        True, _ -> #(
          bool_to_int(game.home_score > game.away_score),
          bool_to_int(game.home_score < game.away_score),
          game.home_score,
          game.away_score,
        )
        _, True -> #(
          bool_to_int(game.away_score > game.home_score),
          bool_to_int(game.away_score < game.home_score),
          game.away_score,
          game.home_score,
        )
        _, _ -> #(0, 0, 0, 0)
      }
    _ -> #(0, 0, 0, 0)
  }
}

fn bool_to_int(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
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
          ui.section_head(name, ""),
          html.article([attribute.class("card team-record-card")], [
            html.header([attribute.class("team-record-title")], [
              html.strong([], [html.text(code)]),
              html.text(" · " <> name),
            ]),
            html.dl([attribute.class("team-record-grid")], [
              stat_item(
                "W-L",
                int.to_string(wins) <> "-" <> int.to_string(losses),
              ),
              stat_item("PF", int.to_string(points_for)),
              stat_item("PA", int.to_string(points_against)),
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

fn stat_item(label: String, value: String) -> Element(msg) {
  html.div([], [
    html.dt([], [html.text(label)]),
    html.dd([], [html.text(value)]),
  ])
}

pub fn view_team_page(
  team: Option(Model),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.main([], [view_team_detail(team, on_navigate_team, on_navigate_game)])
}
