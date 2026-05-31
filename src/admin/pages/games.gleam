import admin/views/games as shared_admin_games_page
import api/domain/game.{type AdminGameSummary}
import generated/proute/admin/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}

pub type Model {
  Model(games: List(AdminGameSummary))
}

pub type Message {
  AdjustAway(id: Int, home_score: Int, away_score: Int, delta: Int)
  AdjustHome(id: Int, home_score: Int, away_score: Int, delta: Int)
  MarkFinal(id: Int)
}

pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  #(initial_model(page_context, query_params), effect.none())
}

pub fn initial_model(
  _page_context: PageContext,
  _query_params: page_input.QueryParams,
) -> Model {
  Model(games: [])
}

pub fn update(
  _page_context: PageContext,
  model: Model,
  _msg: Message,
) -> #(Model, Effect(Message)) {
  #(model, effect.none())
}

pub fn view(model model: Model) -> Element(Message) {
  shared_admin_games_page.view(
    model.games,
    fn(id, home_score, away_score, delta) {
      AdjustAway(id:, home_score:, away_score:, delta:)
    },
    fn(id, home_score, away_score, delta) {
      AdjustHome(id:, home_score:, away_score:, delta:)
    },
    fn(id) { MarkFinal(id:) },
  )
}
