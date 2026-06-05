@target(erlang)
import generated/proute/admin/page_input as admin_page_input
@target(erlang)
import generated/proute/admin/pages as admin_pages
@target(erlang)
import generated/proute/admin/routes as admin_routes
@target(erlang)
import generated/proute/public/page_input as public_page_input
@target(erlang)
import generated/proute/public/pages as public_pages
@target(erlang)
import generated/proute/public/routes as public_routes
@target(erlang)
import generated/rally/server_ssr

@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/option.{type Option, None, Some}

@target(erlang)
import lustre/element
@target(erlang)
import mist.{type Connection}
@target(erlang)
import sqlight

@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import app_auth
@target(erlang)
import app_auth_http
@target(erlang)
import app_session
@target(erlang)
import app_shell
@target(erlang)
import authentication_context.{type AuthenticationContext}
@target(erlang)
import page_context.{PageContext}
@target(erlang)
import public/pages/games as public_games_page
@target(erlang)
import public/pages/games/id_ as public_game_detail_page
@target(erlang)
import public/pages/standings as public_standings_page
@target(erlang)
import public/pages/teams/slug_ as public_team_detail_page

// TYPES

@target(erlang)
pub type SsrApp {
  SsrApp(html: String, hydration: List(String))
}

// PUBLIC

@target(erlang)
pub fn public(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: app_session.Session,
) -> SsrApp {
  let #(authentication_context, can_access_admin) =
    boot_identity(req: req, db: db, session: session)

  public_render(
    path:,
    db:,
    query_params:,
    dark_mode:,
    authentication_context:,
    can_access_admin:,
  )
}

@target(erlang)
pub fn public_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
  can_access_admin can_access_admin: Bool,
) -> SsrApp {
  let route = public_routes.parse_path(path)
  let #(page, hydration) = public_boot_page(db, query_params, route)

  SsrApp(
    html: app_shell.public(
      current_path: public_routes.route_to_path(route),
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      can_access_admin: can_access_admin,
      on_dark_mode_change: fn(_) { Nil },
      content: public_pages.view(page) |> element.map(fn(_) { Nil }),
    )
      |> element.to_string,
    hydration: hydration,
  )
}

// ADMIN

@target(erlang)
pub fn admin(
  req req: Request(Connection),
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  session session: app_session.Session,
) -> SsrApp {
  let #(authentication_context, _) =
    boot_identity(req: req, db: db, session: session)

  admin_render(path:, db:, query_params:, dark_mode:, authentication_context:)
}

@target(erlang)
pub fn admin_render(
  path path: String,
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  dark_mode dark_mode: Bool,
  authentication_context authentication_context: Option(AuthenticationContext),
) -> SsrApp {
  let route = admin_routes.parse_path(path)
  let #(page, hydration) = admin_boot_page(db, query_params, route)

  SsrApp(
    html: app_shell.admin(
      current_path: admin_routes.route_to_path(route),
      dark_mode: dark_mode,
      authentication_context: authentication_context,
      on_dark_mode_change: fn(_) { Nil },
      content: admin_pages.view(page) |> element.map(fn(_) { Nil }),
    )
      |> element.to_string,
    hydration: hydration,
  )
}

// HELPERS

@target(erlang)
fn public_boot_page(
  db db: sqlight.Connection,
  query_params query_params: public_page_input.QueryParams,
  route route: public_routes.Route,
) -> #(public_pages.Page, List(String)) {
  server_ssr.public_boot_page(
    page_context: PageContext,
    query_params:,
    route:,
    select_load: public_load_route,
    handlers: public_load_handlers(db),
    update_page: public_pages.update,
  )
}

@target(erlang)
fn admin_boot_page(
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  route route: admin_routes.Route,
) -> #(admin_pages.Page, List(String)) {
  server_ssr.admin_boot_page(
    page_context: PageContext,
    query_params:,
    route:,
    select_load: admin_load_route,
    handlers: admin_load_handlers(db),
    update_page: fn(page, message) {
      admin_pages.update(PageContext, page, message)
    },
  )
}

@target(erlang)
fn public_load_route(route: public_routes.Route) -> server_ssr.PublicLoadRoute {
  case route {
    public_routes.Home ->
      server_ssr.PublicGamesLoad(to_message: fn(result) {
        public_pages.HomeMsg(public_games_page.loaded_from_wire(result))
      })
    public_routes.Games ->
      server_ssr.PublicGamesLoad(to_message: fn(result) {
        public_pages.GamesMsg(public_games_page.loaded_from_wire(result))
      })
    public_routes.GamesId(_) ->
      server_ssr.PublicGameDetailLoad(to_message: fn(result) {
        public_pages.GamesIdMsg(public_game_detail_page.loaded_from_wire(result))
      })
    public_routes.Standings ->
      server_ssr.PublicStandingsLoad(to_message: fn(result) {
        public_pages.StandingsMsg(public_standings_page.loaded_from_wire(result))
      })
    public_routes.TeamsSlug(_) ->
      server_ssr.PublicTeamDetailLoad(to_message: fn(result) {
        public_pages.TeamsSlugMsg(public_team_detail_page.loaded_from_wire(
          result,
        ))
      })
    public_routes.SignIn | public_routes.NotFound -> server_ssr.PublicNoLoad
  }
}

@target(erlang)
fn public_load_handlers(
  db: sqlight.Connection,
) -> server_ssr.PublicLoadHandlers {
  server_ssr.PublicLoadHandlers(
    public_games_load: fn(_route) { public_games_page.load_wire(db) },
    public_game_detail_load: fn(route) {
      case route {
        public_routes.GamesId(id) ->
          case int.parse(id) {
            Ok(game_id) -> public_game_detail_page.load_wire(db, game_id)
            Error(Nil) -> Error(["Game not found."])
          }
        _ -> Error(["Unexpected game route."])
      }
    },
    public_standings_load: fn(_route) { public_standings_page.load_wire(db) },
    public_team_detail_load: fn(route) {
      case route {
        public_routes.TeamsSlug(slug) ->
          public_team_detail_page.load_wire(db, slug)
        _ -> Error(["Unexpected team route."])
      }
    },
  )
}

@target(erlang)
fn admin_load_route(route: admin_routes.Route) -> server_ssr.AdminLoadRoute {
  case route {
    admin_routes.AdminHome ->
      server_ssr.AdminGamesLoad(to_message: fn(result) {
        admin_pages.AdminHomeMsg(admin_games_page.loaded_from_wire(result))
      })
    admin_routes.AdminGames ->
      server_ssr.AdminGamesLoad(to_message: fn(result) {
        admin_pages.AdminGamesMsg(admin_games_page.loaded_from_wire(result))
      })
    admin_routes.NotFound -> server_ssr.AdminNoLoad
  }
}

@target(erlang)
fn admin_load_handlers(db: sqlight.Connection) -> server_ssr.AdminLoadHandlers {
  server_ssr.AdminLoadHandlers(admin_games_load: fn(_route) {
    admin_games_page.load_wire(db)
  })
}

@target(erlang)
fn boot_identity(
  req req: Request(Connection),
  db db: sqlight.Connection,
  session session: app_session.Session,
) -> #(Option(AuthenticationContext), Bool) {
  case app_auth_http.authenticated_user(req: req, db: db, session: session) {
    Ok(user) -> #(Some(user.context), app_auth.can_access_admin(user))
    Error(Nil) -> #(None, False)
  }
}
