import api/domain/game.{
  type GameSnapshot, type PublicGameSummary, Final, PublicGameSummary,
}
import api/domain/team.{type TeamDetail, TeamDetail}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import components/game_card
import components/ui
import generated/proute/public/page_input
import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import page_context.{type PageContext}

pub type Model {
  Model(team: Option(TeamDetail))
}

pub type Message {
  NavigateTeam(slug: String)
  NavigateGame(id: Int)
}

pub fn init(
  page_context page_context: PageContext,
  route_params route_params: page_input.TeamsSlugRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(
    initial_model(page_context, route_params, query_params),
    init_effect(route_params.slug),
  )
}

pub fn initial_model(
  _page_context: PageContext,
  _route_params: page_input.TeamsSlugRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(team: None)
}

pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn team_loaded(
  model _model: Model,
  team team: TeamDetail,
) -> #(Model, Effect(Message)) {
  #(Model(team: Some(team)), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Message)) {
  case model.team {
    Some(team) -> #(
      Model(team: Some(apply_game_updated(team, game))),
      effect.none(),
    )
    None -> #(model, effect.none())
  }
}

pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    view_team_detail(model.team, fn(slug) { NavigateTeam(slug:) }, fn(id) {
      NavigateGame(id:)
    }),
  ])
}

fn apply_game_updated(team: TeamDetail, snapshot: GameSnapshot) -> TeamDetail {
  use <- bool.guard(!game_belongs_to_team(team.code, snapshot), team)
  apply_team_game_update(team, snapshot)
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
  team: Option(TeamDetail),
  on_navigate_team: fn(String) -> msg,
  on_navigate_game: fn(Int) -> msg,
) -> Element(msg) {
  case team {
    None -> html.p([attribute.class("muted")], [html.text("Loading team...")])
    Some(detail) -> {
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
                  game_card.public_summary(
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

@target(javascript)
fn init_effect(slug: String) -> Effect(Message) {
  api_client.send(module: "public/teams", message: to_server.LoadTeam(slug:))
}

@target(erlang)
fn init_effect(_slug: String) -> Effect(Message) {
  effect.none()
}
