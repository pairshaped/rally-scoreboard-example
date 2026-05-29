//// Browser entry point for the public Mount.
////
//// Owns the public Lustre application shell: route parsing, page model
//// storage, ToClient fanout, navigation, and public view composition.

import generated/codec
import generated/public/route as public_route
import generated/public/router as public_router
import generated/public/to_client as public_to_client_dispatch
import generated/runtime/effect as public_effect
import generated/setup
import generated/transport
import gleam/dict.{type Dict}
import gleam/int
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
import shared/api/to_client as public_to_client
import shared/components/ui
import shared/public/client_shared_state.{type PublicClientSharedState}
import shared/public/pages/games as public_games_page
import shared/public/pages/games/id_ as public_game_detail_page
import shared/public/pages/standings as public_standings_page
import shared/public/pages/teams/slug_ as public_team_page

type Model {
  Model(
    route: public_route.Route,
    pages: public_to_client_dispatch.Models,
    dark_mode: Bool,
    // Route query params are stored so app code can react to query-driven
    // filters (e.g. ?team=TOR). The initial load and page-init paths both
    // forward query to the server through RequestContext.
    query: Dict(String, String),
    context: Option(PublicClientSharedState),
  )
}

type Msg {
  ServerEvent(public_to_client.ToClient)
  PageMsg(public_to_client_dispatch.Msg)
  Navigate(public_route.Route)
  UrlChanged(Uri)
  SetDarkMode(Bool)
}

pub fn main() -> Nil {
  let assert True = codec.ensure_decoders()
  setup.setup()

  let ssr_event = case setup.read_ssr_to_client() {
    option.Some(value) -> {
      let event: public_to_client.ToClient = transport.coerce(value)
      option.Some(event)
    }
    option.None -> option.None
  }
  let context = case setup.read_client_shared_state() {
    option.Some(value) -> {
      let ctx: PublicClientSharedState = transport.coerce(value)
      option.Some(ctx)
    }
    option.None -> option.None
  }

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", #(ssr_event, context))
  Nil
}

fn init(
  flags: #(Option(public_to_client.ToClient), Option(PublicClientSharedState)),
) -> #(Model, Effect(Msg)) {
  let #(ssr_event, context) = flags
  let uri_result = modem.initial_uri()
  let route =
    uri_result
    |> result.map(public_router.parse_uri)
    |> result.unwrap(public_route.NotFound)
  let query = case uri_result {
    Ok(uri) -> query_from_uri(uri)
    Error(Nil) -> dict.new()
  }
  let pages = public_to_client_dispatch.init()
  let model =
    Model(
      route:,
      pages:,
      dark_mode: public_effect.read_dark_mode(),
      query:,
      context:,
    )
  let #(model, hydrated, hydration_effect) = case ssr_event {
    option.Some(event) -> {
      let #(pages, page_eff) =
        public_to_client_dispatch.apply_to_client(model.pages, event)
      #(Model(..model, pages:), True, effect.map(page_eff, PageMsg))
    }
    option.None -> #(model, False, effect.none())
  }
  let load_effect = case hydrated {
    True -> effect.none()
    False -> initial_load(route)
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

/// Sends init_requests() commands over WebSocket when SSR hydration is absent.
/// init_requests() on the shared page is the source of truth for what commands
/// are needed; generated client init sends the returned commands verbatim.
fn initial_load(route: public_route.Route) -> Effect(Msg) {
  case route {
    public_route.Games ->
      case public_games_page.init_requests() {
        [req, ..] -> public_effect.send_to_server(req)
        [] -> effect.none()
      }
    public_route.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          case public_game_detail_page.init_requests(game_id:) {
            [req, ..] -> public_effect.send_to_server(req)
            [] -> effect.none()
          }
        Error(Nil) -> effect.none()
      }
    public_route.Standings ->
      case public_standings_page.init_requests() {
        [req, ..] -> public_effect.send_to_server(req)
        [] -> effect.none()
      }
    public_route.Team(slug) ->
      case public_team_page.init_requests(slug:) {
        [req, ..] -> public_effect.send_to_server(req)
        [] -> effect.none()
      }
    public_route.SignIn
    | public_route.SignInPassword
    | public_route.SignInCode
    | public_route.NotFound -> effect.none()
  }
}

fn register_to_client_handlers() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    transport.register_push_handler("to_client", fn(value) {
      let event: public_to_client.ToClient = transport.coerce(value)
      dispatch(ServerEvent(event))
    })
  })
}

/// Sends page_init plus init_requests() commands over WebSocket for SPA
/// navigation. init_requests() on the shared page is the source of truth
/// for what commands are needed; the returned command is sent verbatim.
fn load_route(
  route: public_route.Route,
  query: Dict(String, String),
) -> Effect(Msg) {
  let #(module, params) = route_page_init(route)
  case route {
    public_route.Games ->
      case public_games_page.init_requests() {
        [req, ..] ->
          public_effect.send_page_init_and_command(
            module:,
            params:,
            query:,
            command: req,
          )
        [] -> effect.none()
      }
    public_route.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          case public_game_detail_page.init_requests(game_id:) {
            [req, ..] ->
              public_effect.send_page_init_and_command(
                module:,
                params:,
                query:,
                command: req,
              )
            [] -> effect.none()
          }
        Error(Nil) -> effect.none()
      }
    public_route.Standings ->
      case public_standings_page.init_requests() {
        [req, ..] ->
          public_effect.send_page_init_and_command(
            module:,
            params:,
            query:,
            command: req,
          )
        [] -> effect.none()
      }
    public_route.Team(slug) ->
      case public_team_page.init_requests(slug:) {
        [req, ..] ->
          public_effect.send_page_init_and_command(
            module:,
            params:,
            query:,
            command: req,
          )
        [] -> effect.none()
      }
    public_route.SignIn
    | public_route.SignInPassword
    | public_route.SignInCode
    | public_route.NotFound -> effect.none()
  }
}

fn route_page_init(route: public_route.Route) -> #(String, String) {
  case route {
    public_route.Games -> #("Games", "null")
    public_route.GamesId(id) -> #("GamesId", id)
    public_route.Standings -> #("Standings", "null")
    public_route.Team(slug) -> #("Team", slug)
    public_route.SignIn
    | public_route.SignInPassword
    | public_route.SignInCode
    | public_route.NotFound -> #("NotFound", "null")
  }
}

fn query_from_uri(uri: Uri) -> Dict(String, String) {
  case uri.query {
    Some(q) ->
      uri.parse_query(q)
      |> result.unwrap([])
      |> dict.from_list
    None -> dict.new()
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Navigate(route) -> #(
      model,
      modem.push(public_router.route_to_path(route:), None, None),
    )
    UrlChanged(uri) -> {
      let route = public_router.parse_uri(uri)
      let query = query_from_uri(uri)
      #(Model(..model, route:, query:), load_route(route, query))
    }
    ServerEvent(event) -> {
      let #(pages, eff) =
        public_to_client_dispatch.apply_to_client(model.pages, event)
      #(
        Model(..model, pages:),
        effect.batch([
          effect.map(eff, PageMsg),
          active_route_refresh(route: model.route, event:),
        ]),
      )
    }
    PageMsg(msg) -> {
      let #(pages, eff) =
        public_to_client_dispatch.update_page(model.pages, msg)
      #(Model(..model, pages:), effect.map(eff, PageMsg))
    }
    SetDarkMode(enabled) -> #(
      Model(..model, dark_mode: enabled),
      public_effect.set_dark_mode(enabled),
    )
  }
}

fn active_route_refresh(
  route route: public_route.Route,
  event event: public_to_client.ToClient,
) -> Effect(Msg) {
  case event, route {
    public_to_client.GameUpdated(_), public_route.Standings ->
      initial_load(route)
    _, _ -> effect.none()
  }
}

fn view(model: Model) -> Element(Msg) {
  let on_navigate_team = fn(slug: String) -> Msg {
    Navigate(public_route.Team(slug:))
  }
  let on_navigate_game = fn(id: Int) -> Msg {
    Navigate(public_route.GamesId(int.to_string(id)))
  }

  html.div([attribute.class("scoreboard-app")], [
    topbar(
      route: model.route,
      dark_mode: model.dark_mode,
      context: model.context,
    ),
    explainer(route: model.route),
    case model.route {
      public_route.Games ->
        public_games_page.view(
          model.pages.games_page.games,
          on_navigate_team,
          on_navigate_game,
        )
      public_route.GamesId(_) ->
        public_game_detail_page.view(
          model.pages.game_detail_page.game,
          on_navigate_team,
        )
      public_route.Standings ->
        public_standings_page.view(
          model.pages.standings_page.rows,
          on_navigate_team,
        )
      public_route.Team(_) ->
        public_team_page.view(
          model.pages.team_page.team,
          on_navigate_team,
          on_navigate_game,
        )
      public_route.SignIn ->
        sign_in_view(public_route.SignInPassword, model.query)
      public_route.SignInPassword ->
        sign_in_view(public_route.SignInPassword, model.query)
      public_route.SignInCode ->
        sign_in_view(public_route.SignInCode, model.query)
      public_route.NotFound -> ui.not_found_view()
    },
  ])
}

fn sign_in_view(
  current: public_route.Route,
  query: Dict(String, String),
) -> Element(Msg) {
  let return_to = dict.get(query, "return_to") |> result.unwrap("")
  let return_to_query = case return_to {
    "" -> ""
    rt -> "?return_to=" <> uri.percent_encode(rt)
  }

  html.main([attribute.class("panel")], [
    html.h1([], [html.text("Sign In")]),
    html.nav([attribute.class("nav")], [
      sign_in_tab(
        path: "/sign_in/password" <> return_to_query,
        label: "Password",
        active: current == public_route.SignInPassword,
      ),
      sign_in_tab(
        path: "/sign_in/code" <> return_to_query,
        label: "Sign-in Code",
        active: current == public_route.SignInCode,
      ),
    ]),
    case current {
      public_route.SignInCode -> sign_in_code_form(return_to)
      _ -> password_form(return_to)
    },
  ])
}

fn password_form(return_to: String) -> Element(Msg) {
  html.form(
    [
      attribute.method("post"),
      attribute.action("/sign_in"),
      attribute.attribute(
        "style",
        "display: grid; gap: 12px; margin-top: 16px;",
      ),
    ],
    [
      html.p([attribute.class("muted")], [
        html.text("Demo account: admin@example.com / admin"),
      ]),
      html.input([
        attribute.type_("hidden"),
        attribute.name("return_to"),
        attribute.value(return_to),
      ]),
      html.input([
        attribute.type_("hidden"),
        attribute.name("code"),
        attribute.value(""),
      ]),
      html.label([], [
        html.text("Email"),
        html.input([
          attribute.name("email"),
          attribute.value("admin@example.com"),
          attribute.autocomplete("email"),
        ]),
      ]),
      html.label([], [
        html.text("Password"),
        html.input([
          attribute.name("password"),
          attribute.value("admin"),
          attribute.type_("password"),
          attribute.autocomplete("current-password"),
        ]),
      ]),
      html.button([], [html.text("Sign In")]),
    ],
  )
}

fn sign_in_code_form(return_to: String) -> Element(Msg) {
  html.form(
    [
      attribute.method("post"),
      attribute.action("/sign_in"),
      attribute.attribute(
        "style",
        "display: grid; gap: 12px; margin-top: 16px;",
      ),
    ],
    [
      html.p([attribute.class("muted")], [
        html.text("Demo sign-in code: A1Z9Q"),
      ]),
      html.input([
        attribute.type_("hidden"),
        attribute.name("return_to"),
        attribute.value(return_to),
      ]),
      html.input([
        attribute.type_("hidden"),
        attribute.name("password"),
        attribute.value(""),
      ]),
      html.label([], [
        html.text("Email"),
        html.input([
          attribute.name("email"),
          attribute.value("admin@example.com"),
          attribute.autocomplete("email"),
        ]),
      ]),
      html.label([], [
        html.text("Sign-in code"),
        html.input([
          attribute.name("code"),
          attribute.value("A1Z9Q"),
          attribute.autocomplete("one-time-code"),
        ]),
      ]),
      html.button([], [html.text("Sign In")]),
    ],
  )
}

fn explainer(route route: public_route.Route) -> Element(Msg) {
  case route {
    public_route.Games ->
      ui.page_explainer("What this page exercises", [
        "Route: generated from the public Mount file path for /games.",
        "Load: sends LoadGames during page init and renders GamesLoaded data.",
        "ToClient: receives GamesLoaded, GameCreated, GameUpdated, and GamesLoadFailed.",
        "Fanout: score updates patch visible game cards without a reload.",
        "Navigation: team and detail links use the generated public router.",
      ])
    public_route.GamesId(id) ->
      ui.page_explainer("What this page exercises", [
        "Route: generated from the public Mount file path for /games/:id.",
        "Load: parses " <> id <> " and sends LoadGame with that game id.",
        "ToClient: receives GameLoaded, GameUpdated, and GamesLoadFailed.",
        "Fanout: score updates for this game patch the detail view score and status.",
      ])
    public_route.Standings ->
      ui.page_explainer("What this page exercises", [
        "Route: generated from the public Mount file path for /standings.",
        "Load: sends LoadStandings during page init.",
        "ToClient: receives StandingsLoaded, GameUpdated, and PowerRankingsLoaded.",
        "Fanout: finalized game results publish fresh standings rows.",
      ])
    public_route.Team(slug) ->
      ui.page_explainer("What this page exercises", [
        "Route: generated from the public Mount file path for /teams/:slug.",
        "Load: sends LoadTeam with the slug " <> slug <> ".",
        "ToClient: receives TeamLoaded, GameCreated, GameUpdated, and GamesLoadFailed.",
        "Fanout: the socket joins games involving this team, so score pushes only arrive for relevant games.",
        "Stats: final game updates patch recent games plus W-L, points for, and points against.",
      ])
    public_route.SignIn | public_route.SignInPassword ->
      ui.page_explainer("What this page exercises", [
        "Route: public-owned sign-in page at /sign_in/password.",
        "Load: renders the password authentication form without a WebSocket connection.",
        "ToServer: form submits to /sign_in via HTTP POST.",
        "ToClient: successful sign-in redirects to the return_to target or /admin/games.",
      ])
    public_route.SignInCode ->
      ui.page_explainer("What this page exercises", [
        "Route: public-owned sign-in page at /sign_in/code.",
        "Load: renders the sign-in code form without a WebSocket connection.",
        "ToServer: form submits to /sign_in via HTTP POST.",
        "ToClient: successful sign-in redirects to the return_to target or /admin/games.",
      ])
    public_route.NotFound ->
      ui.page_explainer("What this page exercises", [
        "Route: falls through the generated public router to NotFound.",
        "Load: no page ToServer command is sent.",
        "ToClient: no page handler is attached for this route.",
      ])
  }
}

fn topbar(
  route route: public_route.Route,
  dark_mode dark_mode: Bool,
  context context: Option(PublicClientSharedState),
) -> Element(Msg) {
  let signed_in = case context {
    Some(ctx) ->
      case ctx.authentication_context {
        Some(_) -> True
        None -> False
      }
    None -> False
  }

  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [
          html.text(case context {
            Some(ctx) -> ctx.league_name
            None -> "Public scores"
          }),
        ]),
      ]),
    ]),
    html.nav([attribute.class("nav")], [
      nav_link(
        route: public_route.Games,
        label: "Games",
        active: is_games(route),
      ),
      nav_link(
        route: public_route.Standings,
        label: "Standings",
        active: route == public_route.Standings,
      ),
      case context {
        Some(ctx) if ctx.can_access_admin ->
          ui.nav_link_external(
            path: "/admin/games",
            label: "Admin",
            active: False,
          )
        _ -> html.text("")
      },
      case signed_in {
        True -> html.a([attribute.href("/sign_out")], [html.text("Sign Out")])
        False ->
          nav_link(
            route: public_route.SignInPassword,
            label: "Sign In",
            active: case route {
              public_route.SignIn
              | public_route.SignInPassword
              | public_route.SignInCode -> True
              _ -> False
            },
          )
      },
      ui.theme_switch(dark_mode, SetDarkMode),
    ]),
  ])
}

fn sign_in_tab(
  path path: String,
  label label: String,
  active active: Bool,
) -> Element(Msg) {
  html.a(
    [
      attribute.href(path),
      attribute.class(case active {
        True -> "active"
        False -> ""
      }),
    ],
    [html.text(label)],
  )
}

fn nav_link(
  route route: public_route.Route,
  label label: String,
  active active: Bool,
) -> Element(Msg) {
  html.a(
    [
      public_router.href(route:),
      attribute.class(case active {
        True -> "active"
        False -> ""
      }),
      event.on_click(Navigate(route)) |> event.prevent_default,
    ],
    [html.text(label)],
  )
}

fn is_games(route: public_route.Route) -> Bool {
  case route {
    public_route.Games | public_route.GamesId(_) -> True
    _ -> False
  }
}
