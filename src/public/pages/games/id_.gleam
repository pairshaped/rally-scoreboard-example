import api/domain/game.{type GameDetail, type GameSnapshot, GameDetail}
@target(javascript)
import api/to_server
@target(javascript)
import client/api as api_client
import components/ui
import generated/proute/public/page_input
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import page_context.{type PageContext}

pub type Model {
  Model(game: Option(GameDetail))
}

pub type Message {
  NavigateTeam(slug: String)
}

pub fn init(
  page_context page_context: PageContext,
  route_params route_params: page_input.GamesIdRouteParams,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(
    initial_model(page_context, route_params, query_params),
    init_effect(route_params.id),
  )
}

pub fn initial_model(
  _page_context: PageContext,
  _route_params: page_input.GamesIdRouteParams,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(game: None)
}

pub fn update(
  model model: Model,
  msg _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn game_loaded(
  model _model: Model,
  game game: GameDetail,
) -> #(Model, Effect(Message)) {
  #(Model(game: Some(game)), effect.none())
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Message)) {
  case model.game {
    Some(detail) if detail.id == game.id -> #(
      Model(game: Some(update_detail(detail, game))),
      effect.none(),
    )
    _ -> #(model, effect.none())
  }
}

pub fn view(model model: Model) -> Element(Message) {
  html.main([], [
    html.section([attribute.class("panel")], [
      ui.section_head("Game detail", ""),
      view_game_detail(model.game, fn(slug) { NavigateTeam(slug:) }),
    ]),
  ])
}

fn view_game_detail(
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

fn update_detail(detail: GameDetail, game: GameSnapshot) -> GameDetail {
  GameDetail(
    ..detail,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
  )
}

@target(javascript)
fn init_effect(id: String) -> Effect(Message) {
  case int.parse(id) {
    Ok(game_id) ->
      api_client.send(
        module: "public/games",
        message: to_server.LoadGame(game_id:),
      )
    Error(Nil) -> effect.none()
  }
}

@target(erlang)
fn init_effect(_id: String) -> Effect(Message) {
  effect.none()
}
