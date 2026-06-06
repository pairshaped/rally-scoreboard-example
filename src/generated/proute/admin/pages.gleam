//// Generated Lustre page glue. Do not edit.
////
//// mount: admin
//// pages: src/admin/pages
//// route_root: /admin
////
//// This module is the generated bridge between route values and page modules.
//// It owns the repetitive Lustre wiring: page unions, page messages, loading
//// dispatch, update forwarding, and rendering dispatch.

import admin/page_shared_state.{type AdminPageSharedState}
import admin/pages/games as admin_games_page
import admin/pages/home_ as admin_home_page
import admin/pages/not_found_ as not_found_page
import generated/proute/admin/page_input
import generated/proute/admin/routes
import lustre/effect.{type Effect}
import lustre/element

/// Page models generated from the admin page tree.
///
/// Each constructor stores the model owned by the matching page module. The
/// mount can keep one `Page` value without knowing each concrete model type.
pub type Page {
  AdminHomePage(model: admin_home_page.Model)
  AdminGamesPage(model: admin_games_page.Model)
  NotFoundPage(model: not_found_page.Model)
}

/// Page messages generated from the admin page tree.
///
/// The mount receives one generated `Message` type and this module forwards
/// the inner message to the page that owns it.
pub type Message {
  AdminHomeMsg(msg: admin_home_page.Message)
  AdminGamesMsg(msg: admin_games_page.Message)
  NotFoundMsg(msg: not_found_page.Message)
}

/// Load the page for a route.
///
/// The mount supplies page shared state and structured query params. This generated
/// function forwards those inputs with any route params into the matching page
/// module's conventional `init` function, then wraps the returned model and
/// effect.
pub fn load(
  page_shared_state page_shared_state: AdminPageSharedState,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> #(Page, Effect(Message)) {
  case route {
    routes.AdminHome -> {
      let #(page_model, page_effect) =
        admin_home_page.init(page_shared_state, query_params)
      #(AdminHomePage(page_model), effect.map(page_effect, AdminHomeMsg))
    }
    routes.AdminGames -> {
      let #(page_model, page_effect) =
        admin_games_page.init(page_shared_state, query_params)
      #(AdminGamesPage(page_model), effect.map(page_effect, AdminGamesMsg))
    }
    routes.NotFound -> {
      let #(page_model, page_effect) =
        not_found_page.init(page_shared_state, query_params)
      #(NotFoundPage(page_model), effect.map(page_effect, NotFoundMsg))
    }
  }
}

/// Build the first page model for server rendering.
///
/// Server-rendered fallback documents cannot wait for Lustre effects, so pages
/// expose synchronous initial models. The generated dispatcher still chooses the
/// page from the route; each page decides what model is safe to render before
/// asynchronous effects have run.
pub fn load_sync(
  page_shared_state page_shared_state: AdminPageSharedState,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> Page {
  case route {
    routes.AdminHome -> {
      AdminHomePage(admin_home_page.initial_model(
        page_shared_state,
        query_params,
      ))
    }
    routes.AdminGames -> {
      AdminGamesPage(admin_games_page.initial_model(
        page_shared_state,
        query_params,
      ))
    }
    routes.NotFound -> {
      NotFoundPage(not_found_page.initial_model(page_shared_state, query_params))
    }
  }
}

/// Forward a page message to the page that owns it.
///
/// Messages that arrive for an inactive page are ignored. This is the same guard
/// a hand-written mount would need, but generated here so user code does not
/// repeat it for every page.
///
/// Pages that need shared app facts during update receive `page_shared_state`;
/// the generated function passes it through without knowing what it contains.
pub fn update(
  page_shared_state page_shared_state: AdminPageSharedState,
  page page: Page,
  message message: Message,
) -> #(Page, Effect(Message)) {
  case page, message {
    AdminHomePage(page_model), AdminHomeMsg(inner) -> {
      let #(new_model, page_effect) =
        admin_home_page.update(page_shared_state, page_model, inner)
      let page = AdminHomePage(new_model)
      #(page, effect.map(page_effect, AdminHomeMsg))
    }
    AdminGamesPage(page_model), AdminGamesMsg(inner) -> {
      let #(new_model, page_effect) =
        admin_games_page.update(page_shared_state, page_model, inner)
      let page = AdminGamesPage(new_model)
      #(page, effect.map(page_effect, AdminGamesMsg))
    }
    NotFoundPage(page_model), NotFoundMsg(inner) -> {
      let #(new_model, page_effect) = not_found_page.update(page_model, inner)
      let page = NotFoundPage(new_model)
      #(page, effect.map(page_effect, NotFoundMsg))
    }
    _, _ -> #(page, effect.none())
  }
}

/// Render the active admin page.
///
/// The mount renders the shell. This generated function renders the selected
/// page and maps its messages back into the generated page message type.
pub fn view(page: Page) -> element.Element(Message) {
  case page {
    AdminHomePage(page_model) ->
      admin_home_page.view(page_model)
      |> element.map(AdminHomeMsg)
    AdminGamesPage(page_model) ->
      admin_games_page.view(page_model)
      |> element.map(AdminGamesMsg)
    NotFoundPage(page_model) ->
      not_found_page.view(page_model)
      |> element.map(NotFoundMsg)
  }
}
