@target(javascript)
import generated/proute/public/page_input
@target(javascript)
import generated/proute/public/pages
@target(javascript)
import generated/proute/public/routes
@target(javascript)
import generated/rally/browser
@target(javascript)
import generated/rally/browser_mount
@target(javascript)
import generated/rally/hydration
@target(javascript)
import generated/rally/public_boot
@target(javascript)
import generated/rally/to_client_application

@target(javascript)
import gleam/int
@target(javascript)
import gleam/list
@target(javascript)
import gleam/option.{type Option, None, Some}

@target(javascript)
import lustre
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}

@target(javascript)
import app_shell
@target(javascript)
import page_context.{PageContext}
@target(javascript)
import public/client_shared_state.{
  type PublicClientSharedState, PublicClientSharedState,
}
@target(javascript)
import public/pages/games as games_page
@target(javascript)
import public/pages/games/id_ as games_id_page
@target(javascript)
import public/pages/standings as standings_page
@target(javascript)
import public/pages/teams/slug_ as teams_slug_page

// TYPES

@target(javascript)
type Model {
  Model(page: pages.Page, shared_state: PublicClientSharedState)
}

@target(javascript)
type Msg {
  PageMsg(pages.Message)
  ServerFrame(BitArray)
  DarkModeChanged(Bool)
  ShellNavigate(String)
  BrowserPathChanged(String)
}

// INIT

@target(javascript)
pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let _started = lustre.start(app, "#app", Nil)
  Nil
}

@target(javascript)
fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let current_path = browser.path()
  let route = routes.parse_path(current_path)
  let query_params = query_params_from_browser()
  let dark_mode = browser_mount.device_dark_mode()
  let #(page, page_effect) =
    initial_page(route: route, query_params: query_params)
  let shared_state =
    PublicClientSharedState(
      league_name: "Scoreboard",
      active_section: current_path,
      dark_mode:,
      authentication_context: browser_mount.boot_authentication_context(),
      can_access_admin: browser.boot_bool("canAccessAdmin"),
    )

  #(
    Model(page: page, shared_state:),
    effect.batch([
      effect.map(page_effect, PageMsg),
      browser_mount.startup_effects(
        dark_mode: dark_mode,
        on_frame: ServerFrame,
        on_shell_navigation: ShellNavigate,
        on_browser_navigation: BrowserPathChanged,
      ),
    ]),
  )
}

@target(javascript)
fn initial_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case route {
    routes.Home | routes.Games -> initial_public_games_page(route, query_params)
    routes.GamesId(_) -> initial_public_game_detail_page(route, query_params)
    routes.Standings -> initial_public_standings_page(route, query_params)
    routes.TeamsSlug(_) -> initial_public_team_detail_page(route, query_params)
    _ -> initial_root_hydrated_page(route, query_params)
  }
}

@target(javascript)
fn initial_public_games_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case hydration.public_games_load_result() {
    Ok(result) -> {
      let page = pages.load_sync(PageContext, query_params, route)
      let message = public_boot.public_games_load_result_message(route, result)
      let #(page, _) = pages.update(page, message)
      #(page, effect.none())
    }
    Error(Nil) -> public_boot.load_client(PageContext, query_params, route)
  }
}

@target(javascript)
fn initial_public_team_detail_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case hydration.public_team_detail_load_result() {
    Ok(result) -> {
      let page = pages.load_sync(PageContext, query_params, route)
      let message =
        public_boot.public_team_detail_load_result_message(route, result)
      let #(page, _) = pages.update(page, message)
      #(page, effect.none())
    }
    Error(Nil) -> public_boot.load_client(PageContext, query_params, route)
  }
}

@target(javascript)
fn initial_public_game_detail_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case hydration.public_game_detail_load_result() {
    Ok(result) -> {
      let page = pages.load_sync(PageContext, query_params, route)
      let message =
        public_boot.public_game_detail_load_result_message(route, result)
      let #(page, _) = pages.update(page, message)
      #(page, effect.none())
    }
    Error(Nil) -> public_boot.load_client(PageContext, query_params, route)
  }
}

@target(javascript)
fn initial_public_standings_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case hydration.public_standings_load_result() {
    Ok(result) -> {
      let page = pages.load_sync(PageContext, query_params, route)
      let message =
        public_boot.public_standings_load_result_message(route, result)
      let #(page, _) = pages.update(page, message)
      #(page, effect.none())
    }
    Error(Nil) -> public_boot.load_client(PageContext, query_params, route)
  }
}

@target(javascript)
fn initial_root_hydrated_page(
  route route: routes.Route,
  query_params query_params: page_input.QueryParams,
) -> #(pages.Page, Effect(pages.Message)) {
  case hydration.messages() {
    Ok(messages) -> {
      let page =
        list.fold(
          messages,
          pages.load_sync(PageContext, query_params, route),
          fn(page, message) {
            let #(page, _) =
              to_client_application.apply_public(page: page, message: message)
            page
          },
        )
      #(page, effect.none())
    }
    Error(Nil) -> public_boot.load_client(PageContext, query_params, route)
  }
}

// UPDATE

@target(javascript)
fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    PageMsg(inner) -> {
      case page_navigation(inner) {
        Some(route) -> navigate(model: model, route: route, push_history: True)
        None -> {
          let #(page, page_effect) = pages.update(model.page, inner)
          #(Model(..model, page: page), effect.map(page_effect, PageMsg))
        }
      }
    }
    ServerFrame(bytes) -> {
      let #(page, page_effect) =
        to_client_application.decode_and_apply_public(
          page: model.page,
          bytes: bytes,
        )
      #(Model(..model, page: page), effect.map(page_effect, PageMsg))
    }
    DarkModeChanged(dark_mode) -> {
      let shared_state =
        PublicClientSharedState(..model.shared_state, dark_mode: dark_mode)
      #(
        Model(..model, shared_state:),
        browser_mount.dark_mode_changed_effects(dark_mode),
      )
    }
    ShellNavigate(path) -> {
      let route = routes.parse_path(path)
      navigate(model: model, route: route, push_history: True)
    }
    BrowserPathChanged(path) -> {
      let route = routes.parse_path(path)
      navigate(model: model, route: route, push_history: False)
    }
  }
}

// VIEW

@target(javascript)
fn view(model: Model) -> Element(Msg) {
  app_shell.public(
    current_path: model.shared_state.active_section,
    dark_mode: model.shared_state.dark_mode,
    authentication_context: model.shared_state.authentication_context,
    can_access_admin: model.shared_state.can_access_admin,
    on_dark_mode_change: DarkModeChanged,
    content: pages.view(model.page) |> element.map(PageMsg),
  )
}

// HELPERS

@target(javascript)
fn page_navigation(message: pages.Message) -> Option(routes.Route) {
  case message {
    pages.GamesMsg(games_page.NavigateTeam(slug)) ->
      Some(routes.TeamsSlug(slug:))
    pages.GamesMsg(games_page.NavigateGame(id)) ->
      Some(routes.GamesId(id: int.to_string(id)))
    pages.GamesIdMsg(games_id_page.NavigateTeam(slug)) ->
      Some(routes.TeamsSlug(slug:))
    pages.StandingsMsg(standings_page.NavigateTeam(slug)) ->
      Some(routes.TeamsSlug(slug:))
    pages.TeamsSlugMsg(teams_slug_page.NavigateTeam(slug)) ->
      Some(routes.TeamsSlug(slug:))
    pages.TeamsSlugMsg(teams_slug_page.NavigateGame(id)) ->
      Some(routes.GamesId(id: int.to_string(id)))
    _ -> None
  }
}

@target(javascript)
fn navigate(
  model model: Model,
  route route: routes.Route,
  push_history push_history: Bool,
) -> #(Model, Effect(Msg)) {
  let path = routes.route_to_path(route)
  let #(page, page_effect) =
    public_boot.load_client(PageContext, page_input.empty_query_params(), route)
  let shared_state =
    PublicClientSharedState(..model.shared_state, active_section: path)
  let history_effect = case push_history {
    True -> browser_mount.push_path(path)
    False -> effect.none()
  }

  #(
    Model(page: page, shared_state:),
    effect.batch([history_effect, effect.map(page_effect, PageMsg)]),
  )
}

@target(javascript)
fn query_params_from_browser() -> page_input.QueryParams {
  page_input.QueryParams(values: browser_mount.query_pairs())
}
