@target(javascript)
import app_shell
@target(javascript)
import authentication_context.{type AuthenticationContext, AuthenticationContext}
@target(javascript)
import browser
@target(javascript)
import client/api as api_client
@target(javascript)
import client/to_client
@target(javascript)
import generated/proute/public/page_input
@target(javascript)
import generated/proute/public/pages
@target(javascript)
import generated/proute/public/routes
@target(javascript)
import gleam/int
@target(javascript)
import gleam/list
@target(javascript)
import gleam/option.{type Option, None, Some}
@target(javascript)
import gleam/string
@target(javascript)
import lustre
@target(javascript)
import lustre/effect.{type Effect}
@target(javascript)
import lustre/element.{type Element}
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

@target(javascript)
type Model {
  Model(page: pages.Page, shared_state: PublicClientSharedState)
}

@target(javascript)
type Msg {
  PageMsg(pages.Message)
  ServerFrame(BitArray)
  DarkModeChanged(Bool)
  BrowserPathChanged(String)
}

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
  let dark_mode = browser.device_dark_mode()
  let #(page, page_effect) = pages.load(PageContext, query_params, route)
  let shared_state =
    PublicClientSharedState(
      league_name: "Scoreboard",
      active_section: current_path,
      dark_mode:,
      authentication_context: boot_authentication_context(),
      can_access_admin: browser.boot_can_access_admin(),
    )

  #(
    Model(page: page, shared_state:),
    effect.batch([
      effect.map(page_effect, PageMsg),
      apply_dark_mode(dark_mode),
      api_client.connect(url: browser.websocket_url(), on_frame: ServerFrame),
      listen_for_browser_navigation(),
    ]),
  )
}

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
        to_client.decode_and_apply_public(page: model.page, bytes: bytes)
      #(Model(..model, page: page), effect.map(page_effect, PageMsg))
    }
    DarkModeChanged(dark_mode) -> {
      let shared_state =
        PublicClientSharedState(..model.shared_state, dark_mode: dark_mode)
      #(
        Model(..model, shared_state:),
        effect.batch([persist_dark_mode(dark_mode), apply_dark_mode(dark_mode)]),
      )
    }
    BrowserPathChanged(path) -> {
      let route = routes.parse_path(path)
      navigate(model: model, route: route, push_history: False)
    }
  }
}

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

@target(javascript)
fn apply_dark_mode(dark_mode: Bool) -> Effect(Msg) {
  effect.from(fn(_dispatch) { browser.apply_dark_mode(dark_mode) })
}

@target(javascript)
fn persist_dark_mode(dark_mode: Bool) -> Effect(Msg) {
  effect.from(fn(_dispatch) { browser.persist_dark_mode(dark_mode) })
}

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
    pages.load(PageContext, page_input.empty_query_params(), route)
  let shared_state =
    PublicClientSharedState(..model.shared_state, active_section: path)
  let history_effect = case push_history {
    True -> push_path(path)
    False -> effect.none()
  }

  #(
    Model(page: page, shared_state:),
    effect.batch([history_effect, effect.map(page_effect, PageMsg)]),
  )
}

@target(javascript)
fn push_path(path: String) -> Effect(Msg) {
  effect.from(fn(_dispatch) { browser.push_path(path) })
}

@target(javascript)
fn listen_for_browser_navigation() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    browser.listen_popstate(fn(path) { dispatch(BrowserPathChanged(path)) })
  })
}

@target(javascript)
fn boot_authentication_context() -> Option(AuthenticationContext) {
  case browser.boot_auth_user_id() {
    0 -> None
    user_id -> {
      let display_name = case browser.boot_auth_display_name() {
        "" -> None
        value -> Some(value)
      }
      Some(AuthenticationContext(
        user_id:,
        email: browser.boot_auth_email(),
        display_name:,
      ))
    }
  }
}

@target(javascript)
fn query_params_from_browser() -> page_input.QueryParams {
  let values =
    browser.query_string()
    |> string.split("&")
    |> list.filter_map(fn(pair) {
      case string.split(pair, "=") {
        [key, value] -> Ok(#(key, value))
        _ -> Error(Nil)
      }
    })
  page_input.QueryParams(values:)
}
