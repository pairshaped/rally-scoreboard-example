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
import gleam/bool
import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
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
import shared/admin/client_shared_state.{type AdminClientSharedState}
import shared/admin/pages/games as admin_games_page
import shared/api/domain/game as admin_game
import shared/api/to_client as admin_to_client
import shared/api/to_server as admin_to_server
import shared/authentication_context
import shared/components/ui

type Model {
  Model(
    route: admin_route.Route,
    games: List(admin_game.AdminGameSummary),
    notice: String,
    home_code: String,
    away_code: String,
    dark_mode: Bool,
    context: Option(AdminClientSharedState),
  )
}

type Msg {
  Received(admin_to_client_dispatch.Msg)
  Navigate(admin_route.Route)
  UrlChanged(Uri)
  CreateGame
  UpdateHomeCode(String)
  UpdateAwayCode(String)
  AdjustHome(Int, Int, Int, Int)
  AdjustAway(Int, Int, Int, Int)
  MarkFinal(Int)
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
  let model =
    Model(
      route:,
      games: [],
      notice: "",
      home_code: "TOR",
      away_code: "NYC",
      dark_mode: admin_effect.read_dark_mode(),
      context:,
    )
  let #(model, hydrated) = case ssr_event {
    option.Some(event) -> {
      let msgs = admin_to_client_dispatch.to_client(event)
      let model =
        list.fold(msgs, model, fn(m, msg) {
          let #(new_m, _) = update(m, Received(msg))
          new_m
        })
      #(model, !list.is_empty(msgs))
    }
    option.None -> #(model, False)
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
    ]),
  )
}

fn register_to_client_handlers() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    transport.register_push_handler("to_client", fn(value) {
      let event: admin_to_client.ToClient = transport.coerce(value)
      admin_to_client_dispatch.to_client(event)
      |> list.each(fn(msg) { dispatch(Received(msg)) })
    })
  })
}

fn load_route(route: admin_route.Route) -> Effect(Msg) {
  case route {
    admin_route.AdminGames ->
      send_admin_games_command(admin_to_server.LoadAdminGames)
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
    Received(admin_to_client_dispatch.GamesPage(page_msg)) ->
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
      send_admin_games_command(admin_to_server.CreateGame(
        home_code: model.home_code,
        away_code: model.away_code,
      )),
    )
    AdjustHome(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      send_admin_games_command(admin_to_server.UpdateScore(
        game_id:,
        home_score: clamp_score(home_score + delta),
        away_score:,
        period: "4th",
      )),
    )
    AdjustAway(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      send_admin_games_command(admin_to_server.UpdateScore(
        game_id:,
        home_score:,
        away_score: clamp_score(away_score + delta),
        period: "4th",
      )),
    )
    MarkFinal(game_id) -> #(
      Model(..model, notice: "Marking final..."),
      send_admin_games_command(admin_to_server.MarkFinal(game_id:)),
    )
    SetDarkMode(enabled) -> #(
      Model(..model, dark_mode: enabled),
      admin_effect.set_dark_mode(enabled),
    )
  }
}

fn handle_games(
  model: Model,
  msg: admin_games_client.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    admin_games_client.LoadedGames(games) -> #(
      Model(..model, games:, notice: ""),
      effect.none(),
    )
    admin_games_client.CreatedGame(game) -> #(
      Model(
        ..model,
        games: upsert_game(games: model.games, detail: game),
        notice: "Game created.",
      ),
      effect.none(),
    )
    admin_games_client.SavedGame(game) -> #(
      Model(
        ..model,
        games: upsert_game(games: model.games, detail: game),
        notice: "Saved.",
      ),
      effect.none(),
    )
    admin_games_client.ScoreUpdated(update) -> #(
      Model(..model, games: apply_score_update(model.games, update)),
      effect.none(),
    )
    admin_games_client.Failed(reason) -> #(
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
      context: model.context,
    ),
    explainer(route: model.route),
    case model.route {
      admin_route.AdminGames ->
        html.main([attribute.class("layout")], [
          html.section([attribute.class("panel")], [
            ui.section_head("Score desk", ""),
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

fn apply_score_update(
  games games: List(admin_game.AdminGameSummary),
  update update: admin_game.GameScoreUpdate,
) -> List(admin_game.AdminGameSummary) {
  list.map(games, fn(game) {
    case game.id == update.game_id {
      True ->
        admin_game.AdminGameSummary(
          ..game,
          home_score: update.home_score,
          away_score: update.away_score,
          status: update.status,
        )
      False -> game
    }
  })
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
