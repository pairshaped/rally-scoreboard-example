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
  type GameSnapshot, type PublicGameSummary, Final, PublicGameSummary,
}
import shared/api/domain/team.{type TeamDetail, TeamDetail}
import shared/api/to_server.{type ToServer}
import shared/components/ui
import shared/public/pages/games as public_games

/// Returns the ToServer commands needed to load team detail data.
///
/// Generated SSR executes these commands locally and embeds the resulting
/// ToClient values for hydration. Generated client init sends these same
/// requests over WebSocket only when hydration has not already populated
/// the page model.
pub fn init_requests(slug slug: String) -> List(ToServer) {
  [to_server.LoadTeam(slug:)]
}

pub type Model {
  Model(team: TeamDetail)
}

pub fn view(
  team: Option(Model),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  html.main([], [view_team_detail(team, on_navigate_team, on_navigate_game)])
}

// nolint: label_possible -- 'model' and 'update' are self-evident from the function name, which already says "apply game updated".
pub fn apply_game_updated(model: Model, snapshot: GameSnapshot) -> Model {
  case game_belongs_to_team(model.team.code, snapshot) {
    False -> model
    True -> Model(team: apply_team_game_update(model.team, snapshot))
  }
}

fn game_belongs_to_team(team_code: String, snapshot: GameSnapshot) -> Bool {
  snapshot.home.code == team_code || snapshot.away.code == team_code
}

fn apply_team_game_update(
  team: TeamDetail,
  snapshot: GameSnapshot,
) -> TeamDetail {
  case list.find(team.recent_games, fn(game) { game.id == snapshot.id }) {
    Error(Nil) -> team
    Ok(existing) -> {
      let updated_games =
        list.map(team.recent_games, fn(game) {
          case game.id == snapshot.id {
            True -> update_game_summary(game, snapshot)
            False -> game
          }
        })
      let #(old_wins, old_losses, old_for, old_against) =
        record_contribution(team.code, existing)
      let #(new_wins, new_losses, new_for, new_against) =
        record_contribution(team.code, update_game_summary(existing, snapshot))

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
  snapshot: GameSnapshot,
) -> PublicGameSummary {
  PublicGameSummary(
    ..game,
    home_score: snapshot.home_score,
    away_score: snapshot.away_score,
    status: snapshot.status,
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

// nolint: prefer_guard_clause -- the case expression is clearer for a bool-to-int conversion than a guard with negation.
fn bool_to_int(value: Bool) -> Int {
  case value {
    True -> 1
    False -> 0
  }
}

fn view_team_detail(
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
