@target(erlang)
import generated/libero/result.{type ApiLoadError, ApiLoadError}
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
import generated/rally/server_protocol

@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/http/request.{type Request}
@target(erlang)
import gleam/int
@target(erlang)
import gleam/list
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
import public/pages/games/id_/wire as public_game_detail_wire
@target(erlang)
import public/pages/games/wire as public_games_wire
@target(erlang)
import public/pages/standings as public_standings_page
@target(erlang)
import public/pages/standings/wire as public_standings_wire
@target(erlang)
import public/pages/teams/slug_ as public_team_detail_page
@target(erlang)
import public/pages/teams/slug_/wire as public_team_detail_wire

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
  let page = public_pages.load_sync(PageContext, query_params, route)

  case route {
    public_routes.Home | public_routes.Games -> {
      let result = public_games_page.load(db)
      #(apply_public_games_load_result(page, route, result), [
        public_games_hydration_payload(result),
      ])
    }
    public_routes.GamesId(id) -> {
      let result = public_game_detail_load(db, id)
      #(apply_public_game_detail_load_result(page, result), [
        public_game_detail_hydration_payload(result),
      ])
    }
    public_routes.Standings -> {
      let result = public_standings_page.load(db)
      #(apply_public_standings_load_result(page, result), [
        public_standings_hydration_payload(result),
      ])
    }
    public_routes.TeamsSlug(slug) -> {
      let result = public_team_detail_page.load(db, slug)
      #(apply_public_team_detail_load_result(page, result), [
        public_team_detail_hydration_payload(result),
      ])
    }
    _ -> {
      #(page, [])
    }
  }
}

@target(erlang)
fn admin_boot_page(
  db db: sqlight.Connection,
  query_params query_params: admin_page_input.QueryParams,
  route route: admin_routes.Route,
) -> #(admin_pages.Page, List(String)) {
  let page = admin_pages.load_sync(PageContext, query_params, route)

  case route {
    admin_routes.AdminHome | admin_routes.AdminGames -> {
      let result = admin_games_page.load(db)
      #(apply_admin_games_load_result(page, route, result), [
        admin_games_hydration_payload(result),
      ])
    }
    admin_routes.NotFound -> #(page, [])
  }
}

@target(erlang)
fn apply_admin_games_load_result(
  page page: admin_pages.Page,
  route route: admin_routes.Route,
  result result: Result(
    List(admin_games_page.AdminGameSummary),
    admin_games_page.LoadError,
  ),
) -> admin_pages.Page {
  let message = case route {
    admin_routes.AdminHome ->
      admin_pages.AdminHomeMsg(admin_games_page.Loaded(result))
    admin_routes.AdminGames ->
      admin_pages.AdminGamesMsg(admin_games_page.Loaded(result))
    admin_routes.NotFound ->
      admin_pages.AdminGamesMsg(
        admin_games_page.Loaded(
          Error(admin_games_page.LoadError(message: "Unexpected admin route.")),
        ),
      )
  }

  let #(page, _) = admin_pages.update(PageContext, page, message)
  page
}

@target(erlang)
fn apply_public_team_detail_load_result(
  page page: public_pages.Page,
  result result: Result(
    public_team_detail_page.TeamDetail,
    public_team_detail_page.LoadError,
  ),
) -> public_pages.Page {
  let message =
    public_pages.TeamsSlugMsg(public_team_detail_page.Loaded(result))
  let #(page, _) = public_pages.update(page, message)
  page
}

@target(erlang)
fn public_game_detail_load(
  db: sqlight.Connection,
  id: String,
) -> Result(
  public_game_detail_page.GameDetail,
  public_game_detail_page.LoadError,
) {
  case int.parse(id) {
    Ok(game_id) -> public_game_detail_page.load(db, game_id)
    Error(Nil) ->
      Error(public_game_detail_page.LoadError(message: "Game not found."))
  }
}

@target(erlang)
fn apply_public_game_detail_load_result(
  page page: public_pages.Page,
  result result: Result(
    public_game_detail_page.GameDetail,
    public_game_detail_page.LoadError,
  ),
) -> public_pages.Page {
  let message = public_pages.GamesIdMsg(public_game_detail_page.Loaded(result))
  let #(page, _) = public_pages.update(page, message)
  page
}

@target(erlang)
fn apply_public_standings_load_result(
  page page: public_pages.Page,
  result result: Result(
    List(public_standings_page.GameSummary),
    public_standings_page.LoadError,
  ),
) -> public_pages.Page {
  let message = public_pages.StandingsMsg(public_standings_page.Loaded(result))
  let #(page, _) = public_pages.update(page, message)
  page
}

@target(erlang)
fn apply_public_games_load_result(
  page page: public_pages.Page,
  route route: public_routes.Route,
  result result: Result(
    List(public_games_page.GameSummary),
    public_games_page.LoadError,
  ),
) -> public_pages.Page {
  let message = case route, result {
    public_routes.Home, Ok(games) ->
      public_pages.HomeMsg(public_games_page.Loaded(Ok(games)))
    public_routes.Games, Ok(games) ->
      public_pages.GamesMsg(public_games_page.Loaded(Ok(games)))
    public_routes.Home, Error(error) ->
      public_pages.HomeMsg(public_games_page.Loaded(Error(error)))
    public_routes.Games, Error(error) ->
      public_pages.GamesMsg(public_games_page.Loaded(Error(error)))
    _, _ ->
      public_pages.GamesMsg(
        public_games_page.Loaded(
          Error(public_games_page.LoadError(
            message: "Unexpected public games route.",
          )),
        ),
      )
  }

  let #(page, _) = public_pages.update(page, message)
  page
}

@target(erlang)
fn public_team_detail_hydration_payload(
  result result: Result(
    public_team_detail_page.TeamDetail,
    public_team_detail_page.LoadError,
  ),
) -> String {
  server_protocol.ensure()
  result
  |> public_team_detail_wire_result
  |> server_protocol.encode_public_team_detail_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn public_game_detail_hydration_payload(
  result result: Result(
    public_game_detail_page.GameDetail,
    public_game_detail_page.LoadError,
  ),
) -> String {
  server_protocol.ensure()
  result
  |> public_game_detail_wire_result
  |> server_protocol.encode_public_game_detail_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn public_standings_hydration_payload(
  result result: Result(
    List(public_standings_page.GameSummary),
    public_standings_page.LoadError,
  ),
) -> String {
  server_protocol.ensure()
  result
  |> public_standings_wire_result
  |> server_protocol.encode_public_standings_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn public_games_hydration_payload(
  result result: Result(
    List(public_games_page.GameSummary),
    public_games_page.LoadError,
  ),
) -> String {
  server_protocol.ensure()
  result
  |> public_games_wire_result
  |> server_protocol.encode_public_games_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn admin_games_hydration_payload(
  result result: Result(
    List(admin_games_page.AdminGameSummary),
    admin_games_page.LoadError,
  ),
) -> String {
  server_protocol.ensure()
  result
  |> admin_games_wire_result
  |> server_protocol.encode_admin_games_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn public_team_detail_wire_result(
  result result: Result(
    public_team_detail_page.TeamDetail,
    public_team_detail_page.LoadError,
  ),
) -> Result(public_team_detail_wire.LoadResult, List(ApiLoadError)) {
  case result {
    Ok(team) ->
      Ok(
        public_team_detail_wire.PublicTeamDetailLoaded(
          public_team_detail_page.to_wire_detail(team),
        ),
      )
    Error(public_team_detail_page.LoadError(message: message)) ->
      Error([ApiLoadError(message:)])
  }
}

@target(erlang)
fn public_game_detail_wire_result(
  result result: Result(
    public_game_detail_page.GameDetail,
    public_game_detail_page.LoadError,
  ),
) -> Result(public_game_detail_wire.LoadResult, List(ApiLoadError)) {
  case result {
    Ok(game) ->
      Ok(
        public_game_detail_wire.PublicGameDetailLoaded(
          public_game_detail_page.to_wire_detail(game),
        ),
      )
    Error(public_game_detail_page.LoadError(message: message)) ->
      Error([ApiLoadError(message:)])
  }
}

@target(erlang)
fn public_standings_wire_result(
  result result: Result(
    List(public_standings_page.GameSummary),
    public_standings_page.LoadError,
  ),
) -> Result(public_standings_wire.LoadResult, List(ApiLoadError)) {
  case result {
    Ok(games) ->
      Ok(
        public_standings_wire.PublicStandingsLoaded(list.map(
          games,
          public_standings_page.to_wire_summary,
        )),
      )
    Error(public_standings_page.LoadError(message: message)) ->
      Error([ApiLoadError(message:)])
  }
}

@target(erlang)
fn public_games_wire_result(
  result result: Result(
    List(public_games_page.GameSummary),
    public_games_page.LoadError,
  ),
) -> Result(public_games_wire.LoadResult, List(ApiLoadError)) {
  case result {
    Ok(games) ->
      Ok(
        public_games_wire.PublicGamesLoaded(list.map(
          games,
          public_games_page.to_wire_summary,
        )),
      )
    Error(public_games_page.LoadError(message: message)) ->
      Error([ApiLoadError(message:)])
  }
}

@target(erlang)
fn admin_games_wire_result(
  result result: Result(
    List(admin_games_page.AdminGameSummary),
    admin_games_page.LoadError,
  ),
) -> Result(admin_games_page.LoadResult, List(ApiLoadError)) {
  case result {
    Ok(games) -> Ok(admin_games_page.AdminGamesLoadResult(games: games))
    Error(admin_games_page.LoadError(message: message)) ->
      Error([ApiLoadError(message:)])
  }
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
