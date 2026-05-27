//// Browser entry point for the admin Mount.
////
//// Owns the admin Lustre application shell: route parsing, page model
//// storage, ToClient fanout, navigation, and admin-only view composition.

import client/admin/receivers as admin_receivers
import generated/admin/receiver_dispatch as admin_receiver_dispatch
import generated/admin/route as admin_route
import generated/admin/router as admin_router
import generated/codec
import generated/runtime/authentication
import generated/runtime/effect as admin_effect
import generated/setup
import generated/transport
import gleam/bool
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import shared/admin/pages/games as admin_games_page
import shared/api/domain/game as admin_game
import shared/api/to_client as admin_to_client
import shared/api/to_server as admin_to_server
import shared/components/ui

type Model {
  Model(
    route: admin_route.Route,
    games: List(admin_game.AdminGameSummary),
    notice: String,
    home_code: String,
    away_code: String,
    dark_mode: Bool,
    signed_in: Bool,
  )
}

type Msg {
  Received(admin_receivers.Msg)
  Navigate(admin_route.Route)
  UrlChanged(Uri)
  CreateGame
  UpdateHomeCode(String)
  UpdateAwayCode(String)
  AdjustHome(Int, Int, Int, Int)
  AdjustAway(Int, Int, Int, Int)
  MarkFinal(Int)
  SetDarkMode(Bool)
  SignOut
}

pub fn main() -> Nil {
  let assert True = codec.ensure_decoders()
  setup.setup()

  let flags = case setup.read_shared_state() {
    option.Some(value) -> {
      let event: admin_to_client.ToClient = transport.coerce(value)
      option.Some(event)
    }
    option.None -> option.None
  }

  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", flags)
  Nil
}

fn init(flags: Option(admin_to_client.ToClient)) -> #(Model, Effect(Msg)) {
  let route =
    modem.initial_uri()
    |> result.map(admin_router.parse_uri)
    |> result.unwrap(admin_route.NotFound)
  let model =
    Model(
      route:,
      games: [],
      notice: "",
      home_code: "TOR",
      away_code: "NYC",
      dark_mode: admin_effect.read_dark_mode(),
      signed_in: admin_effect.has_auth_cookie("scoreboard_admin"),
    )
  let #(model, hydrated) = case flags {
    option.Some(event) -> {
      let msgs = admin_receiver_dispatch.to_client(event)
      let model =
        list.fold(msgs, model, fn(m, receiver_msg) {
          let #(new_m, _) = update(m, Received(receiver_msg))
          new_m
        })
      #(model, !list.is_empty(msgs))
    }
    option.None -> #(model, False)
  }
  let load_effect = case hydrated {
    True -> effect.none()
    False -> load_route(route)
  }
  #(
    model,
    effect.batch([
      register_receivers(),
      modem.advanced(
        modem.Options(
          handle_internal_links: False,
          handle_external_links: False,
        ),
        UrlChanged,
      ),
      load_effect,
    ]),
  )
}

fn register_receivers() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    transport.register_push_handler("to_client", fn(value) {
      let event: admin_to_client.ToClient = transport.coerce(value)
      admin_receiver_dispatch.to_client(event)
      |> list.each(fn(msg) { dispatch(Received(msg)) })
    })
  })
}

fn load_route(route: admin_route.Route) -> Effect(Msg) {
  case route {
    admin_route.AdminSignInPassword | admin_route.AdminSignInCode ->
      effect.none()
    admin_route.AdminGames ->
      admin_effect.send_to_server(admin_to_server.LoadAdminGames)
    admin_route.NotFound -> effect.none()
  }
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
    Received(admin_receivers.GamesPage(page_msg)) ->
      handle_games(model, page_msg)
    UpdateHomeCode(value) -> #(
      Model(..model, home_code: string.uppercase(string.trim(value))),
      effect.none(),
    )
    UpdateAwayCode(value) -> #(
      Model(..model, away_code: string.uppercase(string.trim(value))),
      effect.none(),
    )
    CreateGame -> #(
      Model(..model, notice: "Creating game..."),
      admin_effect.send_to_server(admin_to_server.CreateGame(
        home_code: model.home_code,
        away_code: model.away_code,
      )),
    )
    AdjustHome(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      admin_effect.send_to_server(admin_to_server.UpdateScore(
        game_id:,
        home_score: clamp_score(home_score + delta),
        away_score:,
        period: "4th",
      )),
    )
    AdjustAway(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      admin_effect.send_to_server(admin_to_server.UpdateScore(
        game_id:,
        home_score:,
        away_score: clamp_score(away_score + delta),
        period: "4th",
      )),
    )
    MarkFinal(game_id) -> #(
      Model(..model, notice: "Marking final..."),
      admin_effect.send_to_server(admin_to_server.MarkFinal(game_id:)),
    )
    SetDarkMode(enabled) -> #(
      Model(..model, dark_mode: enabled),
      admin_effect.set_dark_mode(enabled),
    )
    SignOut -> #(model, authentication.sign_out(path: "/admin/sign_out"))
  }
}

fn handle_games(
  model: Model,
  msg: admin_games_page.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    admin_games_page.LoadedGames(games) -> #(
      Model(..model, games:, notice: ""),
      effect.none(),
    )
    admin_games_page.CreatedGame(game) -> #(
      Model(
        ..model,
        games: upsert_game(games: model.games, detail: game),
        notice: "Game created.",
      ),
      effect.none(),
    )
    admin_games_page.SavedGame(game) -> #(
      Model(
        ..model,
        games: upsert_game(games: model.games, detail: game),
        notice: "Saved.",
      ),
      effect.none(),
    )
    admin_games_page.Failed(reason) -> #(
      Model(..model, notice: reason),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("scoreboard-app")], [
    topbar(
      route: model.route,
      dark_mode: model.dark_mode,
      signed_in: model.signed_in,
    ),
    case model.route {
      admin_route.AdminSignInPassword -> sign_in_view(route: model.route)
      admin_route.AdminSignInCode -> sign_in_view(route: model.route)
      admin_route.AdminGames ->
        html.main([attribute.class("layout")], [
          html.section([attribute.class("panel")], [
            ui.section_head(
              "Score desk",
              "Admin commands route through the admin Mount dispatch.",
            ),
            admin_games_page.view_games(
              model.games,
              AdjustAway,
              AdjustHome,
              MarkFinal,
            ),
          ]),
          html.aside([attribute.class("panel admin-tools")], [
            html.h2([], [html.text("Create game")]),
            html.div([attribute.class("toolbar")], [
              html.input([
                attribute.value(model.home_code),
                attribute.placeholder("Home"),
                event.on_input(UpdateHomeCode),
              ]),
              html.input([
                attribute.value(model.away_code),
                attribute.placeholder("Away"),
                event.on_input(UpdateAwayCode),
              ]),
              html.button([event.on_click(CreateGame)], [html.text("Create")]),
            ]),
            html.p([attribute.class("muted")], [html.text(model.notice)]),
          ]),
        ])
      admin_route.NotFound -> ui.not_found_view()
    },
  ])
}

fn topbar(
  route route: admin_route.Route,
  dark_mode dark_mode: Bool,
  signed_in signed_in: Bool,
) -> Element(Msg) {
  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [html.text("Admin score desk")]),
      ]),
    ]),
    html.nav([attribute.class("nav")], [
      ui.nav_link_external(path: "/games", label: "Games", active: False),
      ui.nav_link_external(
        path: "/standings",
        label: "Standings",
        active: False,
      ),
      admin_link(route: route, signed_in: signed_in),
      authentication_link(route: route, signed_in: signed_in),
      ui.theme_switch(dark_mode, SetDarkMode),
    ]),
  ])
}

fn admin_link(
  route route: admin_route.Route,
  signed_in signed_in: Bool,
) -> Element(Msg) {
  case signed_in {
    True ->
      nav_link(
        route: admin_route.AdminGames,
        label: "Admin",
        active: route == admin_route.AdminGames,
      )
    False ->
      ui.nav_link_external(path: "/admin/games", label: "Admin", active: False)
  }
}

fn authentication_link(
  route route: admin_route.Route,
  signed_in signed_in: Bool,
) -> Element(Msg) {
  case signed_in {
    True -> sign_out_link()
    False -> sign_in_link(route)
  }
}

fn sign_in_link(route: admin_route.Route) -> Element(Msg) {
  nav_link(
    route: admin_route.AdminSignInPassword,
    label: "Sign In",
    active: route == admin_route.AdminSignInPassword
      || route == admin_route.AdminSignInCode,
  )
}

fn sign_out_link() -> Element(Msg) {
  html.a(
    [
      attribute.href("/admin/sign_out"),
      event.on_click(SignOut) |> event.prevent_default,
    ],
    [html.text("Sign Out")],
  )
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

fn sign_in_view(route route: admin_route.Route) -> Element(Msg) {
  html.main([attribute.class("panel")], [
    html.h1([], [html.text("Admin Sign In")]),
    html.nav([attribute.class("nav")], [
      nav_link(
        route: admin_route.AdminSignInPassword,
        label: "Password",
        active: route == admin_route.AdminSignInPassword,
      ),
      nav_link(
        route: admin_route.AdminSignInCode,
        label: "Sign-in Code",
        active: route == admin_route.AdminSignInCode,
      ),
    ]),
    case route {
      admin_route.AdminSignInCode -> sign_in_code_form()
      _ -> password_form()
    },
  ])
}

fn password_form() -> Element(Msg) {
  html.form(
    [
      attribute.method("post"),
      attribute.action("/admin/sign_in"),
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

fn sign_in_code_form() -> Element(Msg) {
  html.form(
    [
      attribute.method("post"),
      attribute.action("/admin/sign_in"),
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

fn clamp_score(score: Int) -> Int {
  use <- bool.guard(when: score < 0, return: 0)
  score
}

fn upsert_game(
  games games: List(admin_game.AdminGameSummary),
  detail detail: admin_game.AdminGameDetail,
) -> List(admin_game.AdminGameSummary) {
  upsert_game_summary(
    games:,
    summary: admin_detail_to_summary(detail),
    seen: False,
  )
}

fn upsert_game_summary(
  games games: List(admin_game.AdminGameSummary),
  summary summary: admin_game.AdminGameSummary,
  seen seen: Bool,
) -> List(admin_game.AdminGameSummary) {
  case games {
    [] -> {
      case seen {
        True -> []
        False -> [summary]
      }
    }
    [game, ..rest] -> {
      case game.id == summary.id {
        True -> [
          summary,
          ..upsert_game_summary(games: rest, summary:, seen: True)
        ]
        False -> [game, ..upsert_game_summary(games: rest, summary:, seen:)]
      }
    }
  }
}

fn admin_detail_to_summary(
  game: admin_game.AdminGameDetail,
) -> admin_game.AdminGameSummary {
  admin_game.AdminGameSummary(
    id: game.id,
    home_code: game.home_code,
    away_code: game.away_code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
    needs_attention: False,
  )
}
