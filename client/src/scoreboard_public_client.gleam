//// Browser entry point for the public Mount.
////
//// Owns the public Lustre application shell: route parsing, page model
//// storage, ToClient fanout, navigation, and public view composition.

import client/public/receivers as public_receivers
import generated/codec
import generated/public/receiver_dispatch as public_receiver_dispatch
import generated/public/route as public_route
import generated/public/router as public_router
import generated/runtime/effect as public_effect
import generated/setup
import generated/transport
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg
import lustre/event
import modem
import shared/api/domain/game as public_game
import shared/api/domain/standing
import shared/api/domain/team as public_team
import shared/api/to_client as public_to_client
import shared/api/to_server as public_to_server
import shared/public/pages/game_detail as public_game_detail_page
import shared/public/pages/games as public_games_page
import shared/public/pages/standings as public_standings_page
import shared/public/pages/team as public_team_page

type Model {
  Model(
    route: public_route.Route,
    games: List(public_game.PublicGameSummary),
    selected_game: Option(public_game.GameDetail),
    standings: List(standing.StandingRow),
    team: Option(public_team_page.Model),
    notice: String,
    dark_mode: Bool,
    query: Dict(String, String),
  )
}

type Msg {
  Received(public_receivers.Msg)
  Navigate(public_route.Route)
  UrlChanged(Uri)
  SetDarkMode(Bool)
  Noop
}

pub fn main() -> Nil {
  let assert True = codec.ensure_decoders()
  setup.setup()
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

fn init(_flags: Nil) -> #(Model, Effect(Msg)) {
  let route =
    modem.initial_uri()
    |> result.map(public_router.parse_uri)
    |> result.unwrap(public_route.NotFound)
  #(
    Model(
      route:,
      games: [],
      selected_game: None,
      standings: [],
      team: None,
      notice: "",
      dark_mode: public_effect.read_dark_mode(),
      query: dict.new(),
    ),
    effect.batch([
      register_receivers(),
      modem.advanced(
        modem.Options(
          handle_internal_links: False,
          handle_external_links: False,
        ),
        UrlChanged,
      ),
      load_route(route, dict.new()),
    ]),
  )
}

fn register_receivers() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    transport.register_push_handler("to_client", fn(value) {
      let event: public_to_client.ToClient = transport.coerce(value)
      public_receiver_dispatch.to_client(event)
      |> list.each(fn(msg) { dispatch(Received(msg)) })
    })
  })
}

fn load_route(
  route: public_route.Route,
  query: Dict(String, String),
) -> Effect(Msg) {
  let _query = query
  case route {
    public_route.Games ->
      public_effect.send_to_server(public_to_server.LoadGames)
    public_route.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          public_effect.send_to_server(public_to_server.LoadGame(game_id:))
        Error(Nil) -> effect.none()
      }
    public_route.Standings ->
      public_effect.send_to_server(public_to_server.LoadStandings)
    public_route.Team(slug:) ->
      public_effect.send_to_server(public_to_server.LoadTeam(slug:))
    public_route.NotFound -> effect.none()
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
    Received(public_receivers.GamesPage(page_msg)) ->
      handle_games(model, page_msg)
    Received(public_receivers.GameDetailPage(page_msg)) ->
      handle_game_detail(model, page_msg)
    Received(public_receivers.StandingsPage(page_msg)) ->
      handle_standings(model, page_msg)
    Received(public_receivers.TeamPage(page_msg)) ->
      handle_team(model, page_msg)
    Received(public_receivers.Notice(notice)) -> #(
      Model(..model, notice:),
      effect.none(),
    )
    SetDarkMode(enabled) -> #(
      Model(..model, dark_mode: enabled),
      public_effect.set_dark_mode(enabled),
    )
    Noop -> #(model, effect.none())
  }
}

fn handle_games(
  model: Model,
  msg: public_games_page.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    public_games_page.LoadedGames(games) -> #(
      Model(..model, games:, notice: ""),
      effect.none(),
    )
    public_games_page.UpdatedScore(update) -> #(
      Model(..model, games: update_games(model.games, update)),
      effect.none(),
    )
    public_games_page.LoadFailed(reason) -> #(
      Model(..model, notice: reason),
      effect.none(),
    )
  }
}

fn handle_game_detail(
  model: Model,
  msg: public_game_detail_page.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    public_game_detail_page.LoadedGame(game) -> #(
      Model(..model, selected_game: Some(game), notice: ""),
      effect.none(),
    )
    public_game_detail_page.UpdatedScore(update) -> #(
      Model(
        ..model,
        selected_game: update_selected_game(model.selected_game, update),
      ),
      effect.none(),
    )
    public_game_detail_page.LoadFailed(reason) -> #(
      Model(..model, notice: reason),
      effect.none(),
    )
  }
}

fn handle_standings(
  model: Model,
  msg: public_standings_page.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    public_standings_page.LoadedStandings(rows) -> #(
      Model(..model, standings: rows, notice: ""),
      effect.none(),
    )
    public_standings_page.LoadedPowerRankings(rows) -> #(
      Model(..model, standings: power_rankings_to_standings(rows), notice: ""),
      effect.none(),
    )
  }
}

fn handle_team(
  model: Model,
  msg: public_team_page.Msg,
) -> #(Model, Effect(Msg)) {
  case msg {
    public_team_page.LoadedTeam(team) -> #(
      Model(..model, team: Some(public_team_page.Model(team:)), notice: ""),
      effect.none(),
    )
    public_team_page.LoadFailed(reason) -> #(
      Model(..model, notice: reason),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("scoreboard-app")], [
    topbar(route: model.route, dark_mode: model.dark_mode),
    case model.route {
      public_route.Games ->
        html.main([], [
          html.section([attribute.class("panel")], [
            section_head("Today", "Live scores from the public root API."),
            view_game_grid(model.games),
          ]),
        ])
      public_route.GamesId(_) ->
        html.main([], [
          html.section([attribute.class("panel")], [
            section_head(
              "Game detail",
              "Loaded through a public ToServer message.",
            ),
            view_game_detail(model.selected_game),
          ]),
        ])
      public_route.Standings ->
        html.main([], [
          html.section([attribute.class("panel")], [
            section_head(
              "League table",
              "Standing rows and power rows share a namespace.",
            ),
            view_standings(model.standings),
          ]),
        ])
      public_route.Team(_) ->
        html.main([], [
          view_team_detail(model.team),
        ])
      public_route.NotFound -> not_found_view()
    },
  ])
}

fn topbar(
  route route: public_route.Route,
  dark_mode dark_mode: Bool,
) -> Element(Msg) {
  html.header([attribute.class("topbar")], [
    html.div([attribute.class("brand")], [
      html.span([attribute.class("brand-mark")], [html.text("S")]),
      html.div([], [
        html.strong([], [html.text("Scoreboard")]),
        html.p([attribute.class("muted")], [html.text("Public scores")]),
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
      nav_link_external(path: "/admin/games", label: "Admin", active: False),
      theme_switch(dark_mode),
    ]),
  ])
}

fn theme_switch(dark_mode: Bool) -> Element(Msg) {
  html.label([attribute.class("theme-switch")], [
    sun_icon(),
    html.input([
      attribute.type_("checkbox"),
      attribute.role("switch"),
      attribute.checked(dark_mode),
      event.on_check(SetDarkMode),
    ]),
    moon_icon(),
  ])
}

fn sun_icon() -> Element(Msg) {
  svg.svg(icon_attrs("Light mode"), [
    svg.circle([
      attribute.attribute("cx", "12"),
      attribute.attribute("cy", "12"),
      attribute.attribute("r", "5"),
    ]),
    svg.line(line_attrs(x1: "12", y1: "1", x2: "12", y2: "3")),
    svg.line(line_attrs(x1: "12", y1: "21", x2: "12", y2: "23")),
    svg.line(line_attrs(x1: "4.22", y1: "4.22", x2: "5.64", y2: "5.64")),
    svg.line(line_attrs(x1: "18.36", y1: "18.36", x2: "19.78", y2: "19.78")),
    svg.line(line_attrs(x1: "1", y1: "12", x2: "3", y2: "12")),
    svg.line(line_attrs(x1: "21", y1: "12", x2: "23", y2: "12")),
    svg.line(line_attrs(x1: "4.22", y1: "19.78", x2: "5.64", y2: "18.36")),
    svg.line(line_attrs(x1: "18.36", y1: "5.64", x2: "19.78", y2: "4.22")),
  ])
}

fn moon_icon() -> Element(Msg) {
  svg.svg(icon_attrs("Dark mode"), [
    svg.path([
      attribute.attribute(
        "d",
        "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z",
      ),
    ]),
  ])
}

fn icon_attrs(label: String) -> List(attribute.Attribute(Msg)) {
  [
    attribute.width(16),
    attribute.height(16),
    attribute.attribute("viewBox", "0 0 24 24"),
    attribute.attribute("fill", "none"),
    attribute.attribute("stroke", "currentColor"),
    attribute.attribute("stroke-width", "2"),
    attribute.class("theme-icon"),
    attribute.role("img"),
    attribute.aria("label", label),
  ]
}

fn line_attrs(
  x1 x1: String,
  y1 y1: String,
  x2 x2: String,
  y2 y2: String,
) -> List(attribute.Attribute(Msg)) {
  [
    attribute.attribute("x1", x1),
    attribute.attribute("y1", y1),
    attribute.attribute("x2", x2),
    attribute.attribute("y2", y2),
  ]
}

fn section_head(title: String, subtitle: String) -> Element(Msg) {
  html.div([attribute.class("section-head")], [
    html.div([], [
      html.h1([], [html.text(title)]),
      html.p([attribute.class("muted")], [html.text(subtitle)]),
    ]),
  ])
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

fn nav_link_external(
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

fn view_game_grid(games: List(public_game.PublicGameSummary)) -> Element(Msg) {
  case games {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for scores...")])
    _ ->
      html.div([attribute.class("game-grid")], list.map(games, view_game_card))
  }
}

fn view_game_card(game: public_game.PublicGameSummary) -> Element(Msg) {
  html.article([attribute.class("game-card")], [
    html.div([attribute.class("team-row")], [
      html.a(
        [
          attribute.href("/teams/" <> uri.percent_encode(game.away.slug)),
          event.on_click(Navigate(public_route.Team(slug: game.away.slug)))
            |> event.prevent_default,
        ],
        [html.strong([], [html.text(game.away.name)])],
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.away_score)),
      ]),
    ]),
    html.div([attribute.class("team-row")], [
      html.a(
        [
          attribute.href("/teams/" <> uri.percent_encode(game.home.slug)),
          event.on_click(Navigate(public_route.Team(slug: game.home.slug)))
            |> event.prevent_default,
        ],
        [html.strong([], [html.text(game.home.name)])],
      ),
      html.span([attribute.class("score")], [
        html.text(int.to_string(game.home_score)),
      ]),
    ]),
    html.div([attribute.class("score-line")], [
      status_badge(game.status),
      html.a(
        [
          public_router.href(
            route: public_route.GamesId(int.to_string(game.id)),
          ),
          event.on_click(Navigate(public_route.GamesId(int.to_string(game.id))))
            |> event.prevent_default,
        ],
        [html.text("Details")],
      ),
    ]),
  ])
}

fn view_game_detail(game: Option(public_game.GameDetail)) -> Element(Msg) {
  case game {
    None -> html.p([attribute.class("muted")], [html.text("Loading game...")])
    Some(game) ->
      html.div([], [
        html.div([attribute.class("game-card")], [
          html.div([attribute.class("team-row")], [
            html.a(
              [
                attribute.href("/teams/" <> uri.percent_encode(game.away.slug)),
                event.on_click(
                  Navigate(public_route.Team(slug: game.away.slug)),
                )
                  |> event.prevent_default,
              ],
              [html.strong([], [html.text(game.away.name)])],
            ),
            html.span([attribute.class("score")], [
              html.text(int.to_string(game.away_score)),
            ]),
          ]),
          html.div([attribute.class("team-row")], [
            html.a(
              [
                attribute.href("/teams/" <> uri.percent_encode(game.home.slug)),
                event.on_click(
                  Navigate(public_route.Team(slug: game.home.slug)),
                )
                  |> event.prevent_default,
              ],
              [html.strong([], [html.text(game.home.name)])],
            ),
            html.span([attribute.class("score")], [
              html.text(int.to_string(game.home_score)),
            ]),
          ]),
          status_badge(game.status),
        ]),
        html.h2([], [html.text("Scoring summary")]),
        html.ul(
          [],
          list.map(game.scoring_summary, fn(item) {
            html.li([], [html.text(item)])
          }),
        ),
      ])
  }
}

fn view_standings(rows: List(standing.StandingRow)) -> Element(Msg) {
  case rows {
    [] ->
      html.p([attribute.class("muted")], [html.text("Waiting for standings...")])
    _ ->
      html.table([attribute.class("standings-table")], [
        html.thead([], [
          html.tr([], [
            html.th([], [html.text("Team")]),
            html.th([], [html.text("W")]),
            html.th([], [html.text("L")]),
            html.th([], [html.text("PF")]),
            html.th([], [html.text("PA")]),
          ]),
        ]),
        html.tbody([], list.map(rows, view_standing_row)),
      ])
  }
}

fn view_standing_row(row: standing.StandingRow) -> Element(Msg) {
  html.tr([], [
    html.td([], [
      html.a(
        [
          attribute.href("/teams/" <> uri.percent_encode(row.slug)),
          event.on_click(Navigate(public_route.Team(slug: row.slug)))
            |> event.prevent_default,
        ],
        [
          html.strong([], [html.text(row.team_code)]),
          html.text(" " <> row.team_name),
        ],
      ),
    ]),
    html.td([], [html.text(int.to_string(row.wins))]),
    html.td([], [html.text(int.to_string(row.losses))]),
    html.td([], [html.text(int.to_string(row.points_for))]),
    html.td([], [html.text(int.to_string(row.points_against))]),
  ])
}

fn view_team_detail(team: Option(public_team_page.Model)) -> Element(Msg) {
  case team {
    None -> html.p([attribute.class("muted")], [html.text("Loading team...")])
    Some(public_team_page.Model(team: detail)) -> {
      let public_team.TeamDetail(
        code:,
        name:,
        slug: _,
        wins:,
        losses:,
        points_for:,
        points_against:,
        recent_games:,
      ) = detail
      html.div([], [
        html.section([attribute.class("panel")], [
          section_head(name, "Team details loaded by slug."),
          html.div([attribute.class("stat-card")], [
            html.div([], [
              html.strong([], [html.text(code)]),
              html.text(" · " <> name),
            ]),
            html.div([attribute.class("score-line")], [
              html.span([], [
                html.text(
                  "W-L: " <> int.to_string(wins) <> "-" <> int.to_string(losses),
                ),
              ]),
              html.span([], [html.text("PF: " <> int.to_string(points_for))]),
              html.span([], [html.text("PA: " <> int.to_string(points_against))]),
            ]),
          ]),
        ]),
        html.section([attribute.class("panel")], [
          section_head("Recent games", ""),
          case recent_games {
            [] ->
              html.p([attribute.class("muted")], [html.text("No games yet.")])
            _ ->
              html.div(
                [attribute.class("game-grid")],
                list.map(recent_games, view_game_card),
              )
          },
        ]),
      ])
    }
  }
}

fn status_badge(status: public_game.GameStatus) -> Element(Msg) {
  case status {
    public_game.Scheduled ->
      html.span([attribute.class("badge")], [html.text("Scheduled")])
    public_game.Live(period) ->
      html.span([attribute.class("badge live")], [html.text(period)])
    public_game.Final ->
      html.span([attribute.class("badge final")], [html.text("Final")])
  }
}

fn not_found_view() -> Element(Msg) {
  html.main([attribute.class("panel")], [
    html.h1([], [html.text("Not found")]),
    html.p([attribute.class("muted")], [
      html.text("This page does not exist."),
    ]),
  ])
}

fn is_games(route: public_route.Route) -> Bool {
  case route {
    public_route.Games | public_route.GamesId(_) -> True
    _ -> False
  }
}

fn update_games(
  games: List(public_game.PublicGameSummary),
  update: public_game.GameScoreUpdate,
) -> List(public_game.PublicGameSummary) {
  list.map(games, fn(game) {
    case game.id == update.game_id {
      True ->
        public_game.PublicGameSummary(
          ..game,
          home_score: update.home_score,
          away_score: update.away_score,
          status: update.status,
        )
      False -> game
    }
  })
}

fn update_selected_game(
  game: Option(public_game.GameDetail),
  update: public_game.GameScoreUpdate,
) -> Option(public_game.GameDetail) {
  case game {
    Some(game) if game.id == update.game_id ->
      Some(
        public_game.GameDetail(
          ..game,
          home_score: update.home_score,
          away_score: update.away_score,
          status: update.status,
        ),
      )
    _ -> game
  }
}

fn power_rankings_to_standings(
  rows: List(standing.PowerRankingRow),
) -> List(standing.StandingRow) {
  list.map(rows, fn(row) {
    standing.StandingRow(
      team_code: row.team_code,
      team_name: row.team_name,
      slug: row.slug,
      wins: row.wins,
      losses: row.losses,
      points_for: row.points_for,
      points_against: row.points_against,
    )
  })
}
