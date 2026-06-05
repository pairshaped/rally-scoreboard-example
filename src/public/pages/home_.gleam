import broadcasts
import generated/proute/public/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}
import public/pages/games as games_page

/// Proute page model for the public root route.
/// generated/proute/public/pages stores this inside HomePage, while the page
/// delegates its concrete model shape to the games page.
pub type Model =
  games_page.Model

/// Proute page message for the public root route.
/// generated/proute/public/pages wraps this as HomeMsg, while the page delegates
/// concrete messages to the games page.
pub type Message =
  games_page.Message

/// Proute page init function for the public root route.
/// generated/proute/public/pages calls this when it constructs HomePage.
pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  games_page.init(page_context, query_params)
}

/// Pure starting state for the public root page.
/// The root route is a real Proute page, but it reuses the games page model so
/// SSR, hydration, and browser init all start from the same shape.
pub fn initial_model(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> Model {
  games_page.initial_model(page_context, query_params)
}

/// Proute page update function for the public root route.
/// generated/proute/public/pages calls this when HomeMsg is active.
pub fn update(
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  games_page.update(model:, msg:)
}

pub fn apply_push(
  model model: Model,
  message message: broadcasts.Event,
) -> #(Model, Effect(Message)) {
  games_page.apply_push(model:, message:)
}

pub fn topics(model: Model) -> List(broadcasts.Topic) {
  games_page.topics(model)
}

/// Proute page view function for the public root route.
/// generated/proute/public/pages calls this when rendering HomePage.
pub fn view(model model: Model) -> Element(Message) {
  games_page.view(model:)
}
