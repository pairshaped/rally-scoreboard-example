import admin/pages/games as games_page
import generated/proute/admin/page_input
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import page_context.{type PageContext}

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

/// Proute page init function for the admin root route.
/// generated/proute/admin/pages calls this when it constructs AdminHomePage.
pub fn init(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> #(Model, Effect(Message)) {
  games_page.init(page_context, query_params)
}

/// Pure starting state for the admin root page.
/// The root route is a real Proute page, but it reuses the games page model so
/// SSR, hydration, and browser init all start from the same shape.
pub fn initial_model(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
) -> Model {
  games_page.initial_model(page_context, query_params)
}

/// Proute page update function for the admin root route.
/// generated/proute/admin/pages calls this when AdminHomeMsg is active.
pub fn update(
  page_context page_context: PageContext,
  model model: Model,
  msg msg: Message,
) -> #(Model, Effect(Message)) {
  games_page.update(page_context, model, msg)
}

/// Proute page view function for the admin root route.
/// generated/proute/admin/pages calls this when rendering AdminHomePage.
pub fn view(model model: Model) -> Element(Message) {
  games_page.view(model:)
}
