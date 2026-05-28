//// Browser entry point for the admin Mount.
////
//// Owns the admin Lustre application shell: route parsing, page model
//// storage, ToClient fanout, navigation, and admin-only view composition.
////
//// Admin pages are guarded by the server entry. This client only loads
//// after authentication and admin access have been confirmed.

import client/admin/pages/games as admin_games_client
import generated/admin/route as admin_route
import generated/admin/router as admin_router
import generated/admin/to_client as admin_to_client_dispatch
import generated/codec
import generated/runtime/effect as admin_effect
import generated/setup
import generated/transport
import gleam/dict
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import shared/admin/client_shared_state.{type AdminClientSharedState}
import shared/admin/pages/games as admin_games_page
import shared/api/to_client as admin_to_client
import shared/api/to_server as admin_to_server
import shared/authentication_context
import shared/components/ui

type Model {
  Model(
    route: admin_route.Route,
    pages: admin_to_client_dispatch.Models,
    dark_mode: Bool,
    context: Option(AdminClientSharedState),
  )
}

type Msg {
  ServerEvent(admin_to_client.ToClient)
  PageMsg(admin_to_client_dispatch.Msg)
  Navigate(admin_route.Route)
  UrlChanged(Uri)
  SetDarkMode(Bool)
}

pub fn main() -> Nil {
  let assert True = codec.ensure_decoders()
  setup.setup()

  let ssr_event = case setup.read_ssr_to_client() {
    option.Some(value) -> {
      let event: admin_to_client.ToClient = transport.coerce(value)
      option.Some(event)
    }
    option.None -> option.None
  }
  let context = case setup.read_client_shared_state() {
    option.Some(value) -> {
      let ctx: AdminClientSharedState = transport.coerce(value)
      option.Some(ctx)
    }
    option.None -> option.None
  }

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", #(ssr_event, context))
  Nil
}

fn init(
  flags: #(Option(admin_to_client.ToClient), Option(AdminClientSharedState)),
) -> #(Model, Effect(Msg)) {
  let #(ssr_event, context) = flags
  let route =
    modem.initial_uri()
    |> result.map(admin_router.parse_uri)
    |> result.unwrap(admin_route.NotFound)
  let pages = admin_to_client_dispatch.init()
  let model =
    Model(
      route:,
      pages:,
      dark_mode: admin_effect.read_dark_mode(),
      context:,
    )
  let #(model, hydrated, hydration_effect) = case ssr_event {
    option.Some(event) -> {
      let #(pages, page_eff) =
        admin_to_client_dispatch.apply_to_client(model.pages, event)
      #(Model(..model, pages:), True, effect.map(page_eff, PageMsg))
    }
    option.None -> #(model, False, effect.none())
  }
  let load_effect = case hydrated {
    True -> init_admin_games(route)
    False -> load_route(route)
  }
  #(
    model,
    effect.batch([
      register_to_client_handlers(),
      modem.advanced(
        modem.Options(
          handle_internal_links: False,
          handle_external_links: False,
        ),
        UrlChanged,
      ),
      load_effect,
      hydration_effect,
    ]),
  )
}

fn register_to_client_handlers() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    transport.register_push_handler("to_client", fn(value) {
      let event: admin_to_client.ToClient = transport.coerce(value)
      dispatch(ServerEvent(event))
    })
  })
}

/// Sends init_requests() commands over WebSocket for admin SPA navigation.
/// init_requests() on the shared page is the source of truth.
fn load_route(route: admin_route.Route) -> Effect(Msg) {
  case route {
    admin_route.AdminGames ->
      case admin_games_page.init_requests() {
        [req, ..] -> send_admin_games_command(req)
        [] -> effect.none()
      }
    admin_route.NotFound -> effect.none()
  }
}

fn init_admin_games(route: admin_route.Route) -> Effect(Msg) {
  case route {
    admin_route.AdminGames ->
      admin_effect.send_page_init(
        module: "AdminGames",
        params: "null",
        query: dict.new(),
      )
    _ -> effect.none()
  }
}

fn send_admin_games_command(command: admin_to_server.ToServer) -> Effect(Msg) {
  admin_effect.send_page_init_and_command(
    module: "AdminGames",
    params: "null",
    query: dict.new(),
    command:,
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Navigate(route) -> #(
      model,
      modem.push(admin_router.route_to_path(route:), None, None),
    )
    UrlChanged(uri) -> {
      let route = admin_router.parse_uri(uri)
      #(Model(..model, route:), load_route(route))
    }
    ServerEvent(event) -> {
      let #(pages, eff) =
        admin_to_client_dispatch.apply_to_client(model.pages, event)
      #(Model(..model, pages:), effect.map(eff, PageMsg))
    }
    PageMsg(msg) -> {
      let #(pages, eff) =
        admin_to_client_dispatch.update_page(model.pages, msg)
      #(Model(..model, pages:), effect.map(eff, PageMsg))
    }
    SetDarkMode(enabled) -> #(
      Model(..model, dark_mode: enabled),
      admin_effect.set_dark_mode(enabled),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("scoreboard-app")], [
    topbar(
      route: model.route,
      dark_mode: model.dark_mode,
      context: model.context,
    ),
    explainer(route: model.route),
    case model.route {
      admin_route.AdminGames ->
        html.main([attribute.class("layout")], [
          html.section([attribute.class("panel")], [
            ui.section_head("Score desk", ""),
            admin_games_page.view(
              model.pages.games_page.games,
              fn(game_id, home_score, away_score, delta) {
                PageMsg(admin_to_client_dispatch.GamesPage(
                  admin_games_client.AdjustAway(
                    game_id,
                    home_score,
                    away_score,
                    delta,
                  ),
                ))
              },
              fn(game_id, home_score, away_score, delta) {
                PageMsg(admin_to_client_dispatch.GamesPage(
                  admin_games_client.AdjustHome(
                    game_id,
                    home_score,
                    away_score,
                    delta,
                  ),
                ))
              },
              fn(game_id) {
                PageMsg(admin_to_client_dispatch.GamesPage(
                  admin_games_client.MarkFinal(game_id),
                ))
              },
            ),
          ]),
          html.aside([attribute.class("panel admin-tools")], [
            html.h2([], [html.text("Create game")]),
            html.div([attribute.class("toolbar")], [
              html.input([
                attribute.value(model.pages.games_page.home_code),
                attribute.placeholder("Home"),
                event.on_input(fn(value) {
                  PageMsg(admin_to_client_dispatch.GamesPage(
                    admin_games_client.UpdateHomeCode(value),
                  ))
                }),
              ]),
              html.input([
                attribute.value(model.pages.games_page.away_code),
                attribute.placeholder("Away"),
                event.on_input(fn(value) {
                  PageMsg(admin_to_client_dispatch.GamesPage(
                    admin_games_client.UpdateAwayCode(value),
                  ))
                }),
              ]),
              html.button(
                [event.on_click(
                  PageMsg(admin_to_client_dispatch.GamesPage(
                    admin_games_client.CreateGame,
                  )),
                )],
                [html.text("Create")],
              ),
            ]),
            html.p([attribute.class("muted")], [
              html.text(model.pages.games_page.notice),
            ]),
          ]),
        ])
      admin_route.NotFound -> ui.not_found_view()
    },
  ])
}

fn explainer(route route: admin_route.Route) -> Element(Msg) {
  case route {
    admin_route.AdminGames ->
      ui.page_explainer("What this page exercises", [
        "Route: generated from the admin Mount file path for /admin/games.",
        "Load: sends LoadAdminGames during page init after the socket has request context.",
        "ToServer: sends CreateGame, UpdateScore, and MarkFinal from the score desk controls.",
        "ToClient: receives AdminGamesLoaded, GameCreated, ScoreUpdateSaved, ResultSaved, AdminError, and GameScoreUpdated.",
        "Fanout: joins the admin live update scope so another open admin tab patches the same score cards.",
      ])
    admin_route.NotFound ->
      ui.page_explainer("What this page exercises", [
        "Route: falls through the generated admin router to NotFound.",
        "Load: no page ToServer command is sent.",
        "ToClient: no page handler is attached for this route.",
      ])
  }
}

fn topbar(
  route route: admin_route.Route,
  dark_mode dark_mode: Bool,
  context context: Option(AdminClientSharedState),
) -> Element(Msg) {
  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [
          html.text(case context {
            Some(ctx) -> ctx.league_name <> " admin"
            None -> "Admin score desk"
          }),
        ]),
      ]),
    ]),
    html.nav([attribute.class("nav")], [
      ui.nav_link_external(path: "/games", label: "Games", active: False),
      ui.nav_link_external(
        path: "/standings",
        label: "Standings",
        active: False,
      ),
      nav_link(
        route: admin_route.AdminGames,
        label: "Admin",
        active: route == admin_route.AdminGames,
      ),
      case context {
        Some(ctx) ->
          case ctx.authentication_context {
            Some(ac) ->
              html.span([attribute.class("nav-context")], [
                html.text(authentication_context.display_label(ac)),
              ])
            None -> html.text("")
          }
        None -> html.text("")
      },
      html.a([attribute.href("/sign_out")], [html.text("Sign Out")]),
      ui.theme_switch(dark_mode, SetDarkMode),
    ]),
  ])
}

fn nav_link(
  route route: admin_route.Route,
  label label: String,
  active active: Bool,
) -> Element(Msg) {
  html.a(
    [
      admin_router.href(route:),
      attribute.class(case active {
        True -> "active"
        False -> ""
      }),
      event.on_click(Navigate(route)) |> event.prevent_default,
    ],
    [html.text(label)],
  )
}
