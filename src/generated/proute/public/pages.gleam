//// Generated Lustre page glue. Do not edit.
////
//// mount: public
//// pages: src/public/pages
//// route_root: /
////
//// This module is the generated bridge between route values and page modules.
//// It owns the repetitive Lustre wiring: page unions, page messages, loading
//// dispatch, update forwarding, and rendering dispatch.

import generated/proute/public/page_input
import generated/proute/public/routes
import lustre/effect.{type Effect}
import lustre/element
import page_context.{type PageContext}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
import public/pages/home_ as home_page
import public/pages/not_found_ as not_found_page
import public/pages/sign_in as sign_in_page
import public/pages/standings as standings_page
import public/pages/teams/slug_ as teams_slug_page

/// Page models generated from the public page tree.
///
/// Each constructor stores the model owned by the matching page module. The
/// mount can keep one `Page` value without knowing each concrete model type.
pub type Page {
  HomePage(model: home_page.Model)
  GamesPage(model: games_page.Model)
  GamesIdPage(model: games_id_page.Model)
  SignInPage(model: sign_in_page.Model)
  StandingsPage(model: standings_page.Model)
  TeamsSlugPage(model: teams_slug_page.Model)
  NotFoundPage(model: not_found_page.Model)
}

/// Page messages generated from the public page tree.
///
/// The mount receives one generated `Message` type and this module forwards
/// the inner message to the page that owns it.
pub type Message {
  HomeMsg(msg: home_page.Message)
  GamesMsg(msg: games_page.Message)
  GamesIdMsg(msg: games_id_page.Message)
  SignInMsg(msg: sign_in_page.Message)
  StandingsMsg(msg: standings_page.Message)
  TeamsSlugMsg(msg: teams_slug_page.Message)
  NotFoundMsg(msg: not_found_page.Message)
}

/// Load the page for a route.
///
/// The mount supplies page context and structured query params. This generated
/// function forwards those inputs with any route params into the matching page
/// module's conventional `init` function, then wraps the returned model and
/// effect.
pub fn load(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> #(Page, Effect(Message)) {
  case route {
    routes.Home -> {
      let #(page_model, page_effect) =
        home_page.init(page_context, query_params)
      #(HomePage(page_model), effect.map(page_effect, HomeMsg))
    }
    routes.Games -> {
      let #(page_model, page_effect) =
        games_page.init(page_context, query_params)
      #(GamesPage(page_model), effect.map(page_effect, GamesMsg))
    }
    routes.GamesId(id) -> {
      let route_params = page_input.GamesIdRouteParams(id:)
      let #(page_model, page_effect) =
        games_id_page.init(page_context, route_params, query_params)
      #(GamesIdPage(page_model), effect.map(page_effect, GamesIdMsg))
    }
    routes.SignIn -> {
      let #(page_model, page_effect) =
        sign_in_page.init(page_context, query_params)
      #(SignInPage(page_model), effect.map(page_effect, SignInMsg))
    }
    routes.Standings -> {
      let #(page_model, page_effect) =
        standings_page.init(page_context, query_params)
      #(StandingsPage(page_model), effect.map(page_effect, StandingsMsg))
    }
    routes.TeamsSlug(slug) -> {
      let route_params = page_input.TeamsSlugRouteParams(slug:)
      let #(page_model, page_effect) =
        teams_slug_page.init(page_context, route_params, query_params)
      #(TeamsSlugPage(page_model), effect.map(page_effect, TeamsSlugMsg))
    }
    routes.NotFound -> {
      let #(page_model, page_effect) =
        not_found_page.init(page_context, query_params)
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
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> Page {
  case route {
    routes.Home -> {
      HomePage(home_page.initial_model(page_context, query_params))
    }
    routes.Games -> {
      GamesPage(games_page.initial_model(page_context, query_params))
    }
    routes.GamesId(id) -> {
      let route_params = page_input.GamesIdRouteParams(id:)
      GamesIdPage(games_id_page.initial_model(
        page_context,
        route_params,
        query_params,
      ))
    }
    routes.SignIn -> {
      SignInPage(sign_in_page.initial_model(page_context, query_params))
    }
    routes.Standings -> {
      StandingsPage(standings_page.initial_model(page_context, query_params))
    }
    routes.TeamsSlug(slug) -> {
      let route_params = page_input.TeamsSlugRouteParams(slug:)
      TeamsSlugPage(teams_slug_page.initial_model(
        page_context,
        route_params,
        query_params,
      ))
    }
    routes.NotFound -> {
      NotFoundPage(not_found_page.initial_model(page_context, query_params))
    }
  }
}

/// Forward a page message to the page that owns it.
///
/// Messages that arrive for an inactive page are ignored. This is the same guard
/// a hand-written mount would need, but generated here so user code does not
/// repeat it for every page.
pub fn update(
  page page: Page,
  message message: Message,
) -> #(Page, Effect(Message)) {
  case page, message {
    HomePage(page_model), HomeMsg(inner) -> {
      let #(new_model, page_effect) = home_page.update(page_model, inner)
      let page = HomePage(new_model)
      #(page, effect.map(page_effect, HomeMsg))
    }
    GamesPage(page_model), GamesMsg(inner) -> {
      let #(new_model, page_effect) = games_page.update(page_model, inner)
      let page = GamesPage(new_model)
      #(page, effect.map(page_effect, GamesMsg))
    }
    GamesIdPage(page_model), GamesIdMsg(inner) -> {
      let #(new_model, page_effect) = games_id_page.update(page_model, inner)
      let page = GamesIdPage(new_model)
      #(page, effect.map(page_effect, GamesIdMsg))
    }
    SignInPage(page_model), SignInMsg(inner) -> {
      let #(new_model, page_effect) = sign_in_page.update(page_model, inner)
      let page = SignInPage(new_model)
      #(page, effect.map(page_effect, SignInMsg))
    }
    StandingsPage(page_model), StandingsMsg(inner) -> {
      let #(new_model, page_effect) = standings_page.update(page_model, inner)
      let page = StandingsPage(new_model)
      #(page, effect.map(page_effect, StandingsMsg))
    }
    TeamsSlugPage(page_model), TeamsSlugMsg(inner) -> {
      let #(new_model, page_effect) = teams_slug_page.update(page_model, inner)
      let page = TeamsSlugPage(new_model)
      #(page, effect.map(page_effect, TeamsSlugMsg))
    }
    NotFoundPage(page_model), NotFoundMsg(inner) -> {
      let #(new_model, page_effect) = not_found_page.update(page_model, inner)
      let page = NotFoundPage(new_model)
      #(page, effect.map(page_effect, NotFoundMsg))
    }
    _, _ -> #(page, effect.none())
  }
}

/// Render the active public page.
///
/// The mount renders the shell. This generated function renders the selected
/// page and maps its messages back into the generated page message type.
pub fn view(page: Page) -> element.Element(Message) {
  case page {
    HomePage(page_model) ->
      home_page.view(page_model)
      |> element.map(HomeMsg)
    GamesPage(page_model) ->
      games_page.view(page_model)
      |> element.map(GamesMsg)
    GamesIdPage(page_model) ->
      games_id_page.view(page_model)
      |> element.map(GamesIdMsg)
    SignInPage(page_model) ->
      sign_in_page.view(page_model)
      |> element.map(SignInMsg)
    StandingsPage(page_model) ->
      standings_page.view(page_model)
      |> element.map(StandingsMsg)
    TeamsSlugPage(page_model) ->
      teams_slug_page.view(page_model)
      |> element.map(TeamsSlugMsg)
    NotFoundPage(page_model) ->
      not_found_page.view(page_model)
      |> element.map(NotFoundMsg)
  }
}
