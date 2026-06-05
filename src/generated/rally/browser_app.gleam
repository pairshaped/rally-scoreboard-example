@target(erlang)
pub fn ensure() -> Nil {
  Nil
}

@target(javascript)
import admin/pages/games as admin_games_wire
@target(javascript)
import admin/pages/home_ as admin_pages_home__page
@target(javascript)
import broadcasts as push_payload
@target(javascript)
import generated/proute/admin/page_input as admin_page_input
@target(javascript)
import generated/proute/admin/pages as admin_pages
@target(javascript)
import generated/proute/admin/routes as admin_routes
@target(javascript)
import generated/proute/public/page_input as public_page_input
@target(javascript)
import generated/proute/public/pages as public_pages
@target(javascript)
import generated/proute/public/routes as public_routes
@target(javascript)
import generated/rally/browser_mount
@target(javascript)
import generated/rally/client_protocol
@target(javascript)
import generated/rally/client_transport
@target(javascript)
import generated/rally/hydration
@target(javascript)
import generated/rally/result.{type ApiLoadError, ApiLoadError}
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
import page_context.{type PageContext}
@target(javascript)
import public/pages/games as public_games_wire
@target(javascript)
import public/pages/games/id_ as public_game_detail_wire
@target(javascript)
import public/pages/home_ as public_pages_home__page
@target(javascript)
import public/pages/standings as public_standings_wire
@target(javascript)
import public/pages/teams/slug_ as public_team_detail_wire

@target(javascript)
pub type AdminLoadRoute {
  AdminNoLoad
  AdminGamesLoad(
    message: admin_games_wire.ServerMsg,
    to_message: fn(Result(admin_games_wire.LoadResult, List(ApiLoadError))) ->
      admin_pages.Message,
  )
}

@target(javascript)
pub type PublicLoadRoute {
  PublicNoLoad
  PublicGameDetailLoad(
    message: public_game_detail_wire.ServerMsg,
    to_message: fn(
      Result(public_game_detail_wire.LoadResult, List(ApiLoadError)),
    ) -> public_pages.Message,
  )
  PublicGamesLoad(
    message: public_games_wire.ServerMsg,
    to_message: fn(Result(public_games_wire.LoadResult, List(ApiLoadError))) ->
      public_pages.Message,
  )
  PublicStandingsLoad(
    message: public_standings_wire.ServerMsg,
    to_message: fn(Result(public_standings_wire.LoadResult, List(ApiLoadError))) ->
      public_pages.Message,
  )
  PublicTeamDetailLoad(
    message: public_team_detail_wire.ServerMsg,
    to_message: fn(
      Result(public_team_detail_wire.LoadResult, List(ApiLoadError)),
    ) -> public_pages.Message,
  )
}

@target(javascript)
pub fn admin_load_route(route route: admin_routes.Route) -> AdminLoadRoute {
  case route {
    admin_routes.AdminGames ->
      AdminGamesLoad(
        message: admin_games_wire.AdminGamesLoad,
        to_message: fn(result) {
          case result {
            Ok(admin_games_wire.AdminGamesLoadResult(data)) ->
              admin_pages.AdminGamesMsg(admin_games_wire.Loaded(Ok(data)))
            Error(errors) ->
              admin_pages.AdminGamesMsg(
                admin_games_wire.Loaded(
                  Error(
                    admin_games_wire.LoadError(message: api_load_error(errors)),
                  ),
                ),
              )
          }
        },
      )
    admin_routes.AdminHome ->
      AdminGamesLoad(
        message: admin_games_wire.AdminGamesLoad,
        to_message: fn(result) {
          case result {
            Ok(admin_games_wire.AdminGamesLoadResult(data)) ->
              admin_pages.AdminHomeMsg(admin_games_wire.Loaded(Ok(data)))
            Error(errors) ->
              admin_pages.AdminHomeMsg(
                admin_games_wire.Loaded(
                  Error(
                    admin_games_wire.LoadError(message: api_load_error(errors)),
                  ),
                ),
              )
          }
        },
      )
    _ -> AdminNoLoad
  }
}

@target(javascript)
pub fn public_load_route(route route: public_routes.Route) -> PublicLoadRoute {
  case route {
    public_routes.GamesId(id:) ->
      case int.parse(id) {
        Ok(game_id) ->
          PublicGameDetailLoad(
            message: public_game_detail_wire.PublicGameDetailLoad(game_id:),
            to_message: fn(result) {
              case result {
                Ok(public_game_detail_wire.PublicGameDetailLoaded(data)) ->
                  public_pages.GamesIdMsg(
                    public_game_detail_wire.Loaded(Ok(data)),
                  )
                Error(errors) ->
                  public_pages.GamesIdMsg(
                    public_game_detail_wire.Loaded(
                      Error(
                        public_game_detail_wire.LoadError(
                          message: api_load_error(errors),
                        ),
                      ),
                    ),
                  )
              }
            },
          )
        Error(Nil) -> PublicNoLoad
      }
    public_routes.Games ->
      PublicGamesLoad(
        message: public_games_wire.PublicGamesLoad,
        to_message: fn(result) {
          case result {
            Ok(public_games_wire.PublicGamesLoaded(data)) ->
              public_pages.GamesMsg(public_games_wire.Loaded(Ok(data)))
            Error(errors) ->
              public_pages.GamesMsg(
                public_games_wire.Loaded(
                  Error(
                    public_games_wire.LoadError(message: api_load_error(errors)),
                  ),
                ),
              )
          }
        },
      )
    public_routes.Home ->
      PublicGamesLoad(
        message: public_games_wire.PublicGamesLoad,
        to_message: fn(result) {
          case result {
            Ok(public_games_wire.PublicGamesLoaded(data)) ->
              public_pages.HomeMsg(public_games_wire.Loaded(Ok(data)))
            Error(errors) ->
              public_pages.HomeMsg(
                public_games_wire.Loaded(
                  Error(
                    public_games_wire.LoadError(message: api_load_error(errors)),
                  ),
                ),
              )
          }
        },
      )
    public_routes.Standings ->
      PublicStandingsLoad(
        message: public_standings_wire.PublicStandingsLoad,
        to_message: fn(result) {
          case result {
            Ok(public_standings_wire.PublicStandingsLoaded(data)) ->
              public_pages.StandingsMsg(public_standings_wire.Loaded(Ok(data)))
            Error(errors) ->
              public_pages.StandingsMsg(
                public_standings_wire.Loaded(
                  Error(
                    public_standings_wire.LoadError(message: api_load_error(
                      errors,
                    )),
                  ),
                ),
              )
          }
        },
      )
    public_routes.TeamsSlug(slug:) ->
      PublicTeamDetailLoad(
        message: public_team_detail_wire.PublicTeamDetailLoad(slug:),
        to_message: fn(result) {
          case result {
            Ok(public_team_detail_wire.PublicTeamDetailLoaded(data)) ->
              public_pages.TeamsSlugMsg(
                public_team_detail_wire.Loaded(Ok(data)),
              )
            Error(errors) ->
              public_pages.TeamsSlugMsg(
                public_team_detail_wire.Loaded(
                  Error(
                    public_team_detail_wire.LoadError(message: api_load_error(
                      errors,
                    )),
                  ),
                ),
              )
          }
        },
      )
    _ -> PublicNoLoad
  }
}

@target(javascript)
pub fn admin_message_path(
  message message: admin_pages.Message,
) -> Option(String) {
  case message {
    _ -> None
  }
}

@target(javascript)
pub fn public_message_path(
  message message: public_pages.Message,
) -> Option(String) {
  case message {
    public_pages.GamesMsg(public_games_wire.NavigateGame(id:)) ->
      Some(
        public_routes.route_to_path(
          public_routes.GamesId(id: int.to_string(id)),
        ),
      )
    public_pages.HomeMsg(public_games_wire.NavigateGame(id:)) ->
      Some(
        public_routes.route_to_path(
          public_routes.GamesId(id: int.to_string(id)),
        ),
      )
    public_pages.TeamsSlugMsg(public_team_detail_wire.NavigateGame(id:)) ->
      Some(
        public_routes.route_to_path(
          public_routes.GamesId(id: int.to_string(id)),
        ),
      )
    public_pages.GamesIdMsg(public_game_detail_wire.NavigateTeam(slug:)) ->
      Some(public_routes.route_to_path(public_routes.TeamsSlug(slug: slug)))
    public_pages.GamesMsg(public_games_wire.NavigateTeam(slug:)) ->
      Some(public_routes.route_to_path(public_routes.TeamsSlug(slug: slug)))
    public_pages.HomeMsg(public_games_wire.NavigateTeam(slug:)) ->
      Some(public_routes.route_to_path(public_routes.TeamsSlug(slug: slug)))
    public_pages.StandingsMsg(public_standings_wire.NavigateTeam(slug:)) ->
      Some(public_routes.route_to_path(public_routes.TeamsSlug(slug: slug)))
    public_pages.TeamsSlugMsg(public_team_detail_wire.NavigateTeam(slug:)) ->
      Some(public_routes.route_to_path(public_routes.TeamsSlug(slug: slug)))
    _ -> None
  }
}

@target(javascript)
pub fn admin_page_topics(
  page page: admin_pages.Page,
) -> List(push_payload.Topic) {
  case page {
    admin_pages.AdminGamesPage(model) -> admin_games_wire.topics(model)
    admin_pages.AdminHomePage(model) -> admin_pages_home__page.topics(model)
    _ -> []
  }
}

@target(javascript)
pub fn admin_apply_push(
  page page: admin_pages.Page,
  module _module: String,
  message message: push_payload.Event,
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  case page {
    admin_pages.AdminGamesPage(model) -> {
      let #(model, page_effect) = admin_games_wire.apply_push(model, message)
      #(
        admin_pages.AdminGamesPage(model),
        effect.map(page_effect, admin_pages.AdminGamesMsg),
      )
    }
    admin_pages.AdminHomePage(model) -> {
      let #(model, page_effect) =
        admin_pages_home__page.apply_push(model, message)
      #(
        admin_pages.AdminHomePage(model),
        effect.map(page_effect, admin_pages.AdminHomeMsg),
      )
    }
    _ -> #(page, effect.none())
  }
}

@target(javascript)
pub fn public_page_topics(
  page page: public_pages.Page,
) -> List(push_payload.Topic) {
  case page {
    public_pages.GamesIdPage(model) -> public_game_detail_wire.topics(model)
    public_pages.GamesPage(model) -> public_games_wire.topics(model)
    public_pages.HomePage(model) -> public_pages_home__page.topics(model)
    public_pages.StandingsPage(model) -> public_standings_wire.topics(model)
    public_pages.TeamsSlugPage(model) -> public_team_detail_wire.topics(model)
    _ -> []
  }
}

@target(javascript)
pub fn public_apply_push(
  page page: public_pages.Page,
  module _module: String,
  message message: push_payload.Event,
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  case page {
    public_pages.GamesIdPage(model) -> {
      let #(model, page_effect) =
        public_game_detail_wire.apply_push(model, message)
      #(
        public_pages.GamesIdPage(model),
        effect.map(page_effect, public_pages.GamesIdMsg),
      )
    }
    public_pages.GamesPage(model) -> {
      let #(model, page_effect) = public_games_wire.apply_push(model, message)
      #(
        public_pages.GamesPage(model),
        effect.map(page_effect, public_pages.GamesMsg),
      )
    }
    public_pages.HomePage(model) -> {
      let #(model, page_effect) =
        public_pages_home__page.apply_push(model, message)
      #(
        public_pages.HomePage(model),
        effect.map(page_effect, public_pages.HomeMsg),
      )
    }
    public_pages.StandingsPage(model) -> {
      let #(model, page_effect) =
        public_standings_wire.apply_push(model, message)
      #(
        public_pages.StandingsPage(model),
        effect.map(page_effect, public_pages.StandingsMsg),
      )
    }
    public_pages.TeamsSlugPage(model) -> {
      let #(model, page_effect) =
        public_team_detail_wire.apply_push(model, message)
      #(
        public_pages.TeamsSlugPage(model),
        effect.map(page_effect, public_pages.TeamsSlugMsg),
      )
    }
    _ -> #(page, effect.none())
  }
}

@target(javascript)
pub fn admin_load_client(
  page_context page_context: PageContext,
  query_params query_params: admin_page_input.QueryParams,
  route route: admin_routes.Route,
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  let page = admin_pages.load_sync(page_context, query_params, route)
  #(page, admin_request_effect(route, admin_load_route(route)))
}

@target(javascript)
pub fn admin_load_path(
  page_context page_context: PageContext,
  query_params query_params: admin_page_input.QueryParams,
  path path: String,
) -> #(String, admin_pages.Page, Effect(admin_pages.Message)) {
  let route = admin_routes.parse_path(path)
  let canonical_path = admin_routes.route_to_path(route)
  let #(page, page_effect) =
    admin_load_client(page_context:, query_params:, route:)
  #(canonical_path, page, page_effect)
}

@target(javascript)
pub fn admin_initial_page(
  page_context page_context: PageContext,
  query_params query_params: admin_page_input.QueryParams,
  route route: admin_routes.Route,
  update_page update_page: fn(admin_pages.Page, admin_pages.Message) ->
    #(admin_pages.Page, Effect(admin_pages.Message)),
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  let page = admin_pages.load_sync(page_context, query_params, route)

  case admin_load_route(route) {
    AdminNoLoad -> #(page, effect.none())
    AdminGamesLoad(message: _, to_message:) -> {
      initial_loaded_page(
        page: page,
        hydration: hydration.admin_games_load_result(),
        to_message: to_message,
        load_client: fn() {
          admin_request_effect(route, admin_load_route(route))
        },
        update_page: update_page,
      )
    }
  }
}

@target(javascript)
pub fn admin_initial_page_from_path(
  page_context page_context: PageContext,
  query_params query_params: admin_page_input.QueryParams,
  path path: String,
  update_page update_page: fn(admin_pages.Page, admin_pages.Message) ->
    #(admin_pages.Page, Effect(admin_pages.Message)),
) -> #(admin_pages.Page, Effect(admin_pages.Message)) {
  admin_initial_page(
    page_context:,
    query_params:,
    route: admin_routes.parse_path(path),
    update_page:,
  )
}

@target(javascript)
fn admin_request_effect(
  route _route: admin_routes.Route,
  selected selected: AdminLoadRoute,
) -> Effect(admin_pages.Message) {
  case selected {
    AdminNoLoad -> effect.none()
    AdminGamesLoad(message:, to_message:) ->
      client_transport.send_admin_games_load(message:, on_result: to_message)
  }
}

@target(javascript)
pub fn public_load_client(
  page_context page_context: PageContext,
  query_params query_params: public_page_input.QueryParams,
  route route: public_routes.Route,
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  let page = public_pages.load_sync(page_context, query_params, route)
  #(page, public_request_effect(route, public_load_route(route)))
}

@target(javascript)
pub fn public_load_path(
  page_context page_context: PageContext,
  query_params query_params: public_page_input.QueryParams,
  path path: String,
) -> #(String, public_pages.Page, Effect(public_pages.Message)) {
  let route = public_routes.parse_path(path)
  let canonical_path = public_routes.route_to_path(route)
  let #(page, page_effect) =
    public_load_client(page_context:, query_params:, route:)
  #(canonical_path, page, page_effect)
}

@target(javascript)
pub fn public_initial_page(
  page_context page_context: PageContext,
  query_params query_params: public_page_input.QueryParams,
  route route: public_routes.Route,
  update_page update_page: fn(public_pages.Page, public_pages.Message) ->
    #(public_pages.Page, Effect(public_pages.Message)),
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  let page = public_pages.load_sync(page_context, query_params, route)

  case public_load_route(route) {
    PublicNoLoad -> #(page, effect.none())
    PublicGameDetailLoad(message: _, to_message:) -> {
      initial_loaded_page(
        page: page,
        hydration: hydration.public_game_detail_load_result(),
        to_message: to_message,
        load_client: fn() {
          public_request_effect(route, public_load_route(route))
        },
        update_page: update_page,
      )
    }
    PublicGamesLoad(message: _, to_message:) -> {
      initial_loaded_page(
        page: page,
        hydration: hydration.public_games_load_result(),
        to_message: to_message,
        load_client: fn() {
          public_request_effect(route, public_load_route(route))
        },
        update_page: update_page,
      )
    }
    PublicStandingsLoad(message: _, to_message:) -> {
      initial_loaded_page(
        page: page,
        hydration: hydration.public_standings_load_result(),
        to_message: to_message,
        load_client: fn() {
          public_request_effect(route, public_load_route(route))
        },
        update_page: update_page,
      )
    }
    PublicTeamDetailLoad(message: _, to_message:) -> {
      initial_loaded_page(
        page: page,
        hydration: hydration.public_team_detail_load_result(),
        to_message: to_message,
        load_client: fn() {
          public_request_effect(route, public_load_route(route))
        },
        update_page: update_page,
      )
    }
  }
}

@target(javascript)
pub fn public_initial_page_from_path(
  page_context page_context: PageContext,
  query_params query_params: public_page_input.QueryParams,
  path path: String,
  update_page update_page: fn(public_pages.Page, public_pages.Message) ->
    #(public_pages.Page, Effect(public_pages.Message)),
) -> #(public_pages.Page, Effect(public_pages.Message)) {
  public_initial_page(
    page_context:,
    query_params:,
    route: public_routes.parse_path(path),
    update_page:,
  )
}

@target(javascript)
fn public_request_effect(
  route route: public_routes.Route,
  selected selected: PublicLoadRoute,
) -> Effect(public_pages.Message) {
  case selected {
    PublicNoLoad -> effect.none()
    PublicGameDetailLoad(message:, to_message:) ->
      case route {
        public_routes.GamesId(id: _) ->
          client_transport.send_public_game_detail_load(
            message:,
            on_result: to_message,
          )
        _ -> effect.none()
      }
    PublicGamesLoad(message:, to_message:) ->
      client_transport.send_public_games_load(message:, on_result: to_message)
    PublicStandingsLoad(message:, to_message:) ->
      client_transport.send_public_standings_load(
        message:,
        on_result: to_message,
      )
    PublicTeamDetailLoad(message:, to_message:) ->
      case route {
        public_routes.TeamsSlug(slug: _) ->
          client_transport.send_public_team_detail_load(
            message:,
            on_result: to_message,
          )
        _ -> effect.none()
      }
  }
}

@target(javascript)
pub fn start(
  init init: fn(Nil) -> #(model, Effect(msg)),
  update update: fn(model, msg) -> #(model, Effect(msg)),
  view view: fn(model) -> Element(msg),
) -> Nil {
  let app = lustre.application(init, update, view)
  let _started = lustre.start(app, "#app", Nil)
  Nil
}

@target(javascript)
pub fn startup_effects(
  page_effect page_effect: Effect(page_msg),
  dark_mode dark_mode: Bool,
  on_page on_page: fn(page_msg) -> msg,
  on_frame on_frame: fn(BitArray) -> msg,
  on_shell_navigation on_shell_navigation: fn(String) -> msg,
  on_browser_navigation on_browser_navigation: fn(String) -> msg,
) -> Effect(msg) {
  effect.batch([
    effect.map(page_effect, on_page),
    browser_mount.startup_effects(
      dark_mode: dark_mode,
      on_frame: on_frame,
      on_shell_navigation: on_shell_navigation,
      on_browser_navigation: on_browser_navigation,
    ),
  ])
}

@target(javascript)
pub fn sync_topics(topics topics: List(push_payload.Topic)) -> Effect(msg) {
  client_transport.sync_topics(list.map(topics, push_payload.topic_name))
}

@target(javascript)
pub fn initial_page(
  hydration hydration: Result(result, Nil),
  load_hydrated load_hydrated: fn(result) -> page,
  load_client load_client: fn() -> #(page, Effect(page_msg)),
) -> #(page, Effect(page_msg)) {
  case hydration {
    Ok(result) -> #(load_hydrated(result), effect.none())
    Error(Nil) -> load_client()
  }
}

@target(javascript)
pub fn map_page_effect(
  page_update page_update: #(page, Effect(page_msg)),
  on_page on_page: fn(page_msg) -> msg,
) -> #(page, Effect(msg)) {
  let #(page, page_effect) = page_update
  #(page, effect.map(page_effect, on_page))
}

@target(javascript)
pub fn server_frame_effect(
  page page: page,
  bytes bytes: BitArray,
  apply_push apply_push: fn(page, String, push_payload.Event) ->
    #(page, Effect(page_msg)),
  on_page on_page: fn(page_msg) -> msg,
) -> #(page, Effect(msg)) {
  case client_protocol.decode_server_frame(bytes) {
    Ok(client_protocol.Push(module:, message:)) ->
      map_page_effect(apply_push(page, module, message), on_page)
    Error(Nil) -> #(page, effect.none())
  }
}

@target(javascript)
pub fn navigation_effects(
  path path: String,
  push_history push_history: Bool,
  page_effect page_effect: Effect(page_msg),
  on_page on_page: fn(page_msg) -> msg,
) -> Effect(msg) {
  let history_effect = case push_history {
    True -> browser_mount.push_path(path)
    False -> effect.none()
  }

  effect.batch([history_effect, effect.map(page_effect, on_page)])
}

@target(javascript)
fn initial_loaded_page(
  page page: page,
  hydration hydration: Result(result, Nil),
  to_message to_message: fn(result) -> message,
  load_client load_client: fn() -> Effect(message),
  update_page update_page: fn(page, message) -> #(page, Effect(message)),
) -> #(page, Effect(message)) {
  case hydration {
    Ok(result) -> {
      let #(page, _) = update_page(page, to_message(result))
      #(page, effect.none())
    }
    Error(Nil) -> #(page, load_client())
  }
}

@target(javascript)
fn api_load_error(errors: List(ApiLoadError)) -> String {
  case errors {
    [ApiLoadError(message: message), ..] -> message
    [] -> "Could not load page."
  }
}
