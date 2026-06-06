import admin/page_shared_state.{type AdminPageSharedState}
import admin/pages/games as games_page
import broadcasts
import generated/proute/admin/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}

/// Proute page model for the admin root route.
/// generated/proute/admin/pages stores this inside AdminHomePage, while the page
/// delegates its concrete model shape to the games page.
pub type Model =
  games_page.Model

/// Proute page message for the admin root route.
/// generated/proute/admin/pages wraps this as AdminHomeMsg, while the page
/// delegates concrete messages to the games page.
pub type Message =
  games_page.Message

/// Pure starting state for the admin root page.
/// The root route is a real Proute page, but it reuses the games page model so
/// SSR, hydration, and browser init all start from the same shape.
pub fn initial_model(
  page_shared_state page_shared_state: AdminPageSharedState,
  query_params query_params: page_input.QueryParams,
) -> Model {
  games_page.initial_model(page_shared_state, query_params)
}

/// Proute page update function for the admin root route.
/// generated/proute/admin/pages calls this when AdminHomeMsg is active.
pub fn update(
  page_shared_state page_shared_state: AdminPageSharedState,
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  games_page.update(page_shared_state, model, msg)
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

/// Proute page view function for the admin root route.
/// generated/proute/admin/pages calls this when rendering AdminHomePage.
pub fn view(model model: Model) -> Element(Message) {
  games_page.view(model:)
}
