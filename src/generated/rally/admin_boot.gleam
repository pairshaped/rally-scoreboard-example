import admin/pages/games as admin_games_page
import api/to_client.{type ToClient}
import broadcasts
@target(javascript)
import generated/libero/result as wire_result
@target(javascript)
import generated/proute/admin/page_input
import generated/proute/admin/pages
@target(javascript)
import generated/proute/admin/routes
@target(javascript)
import generated/rally/client_transport
import gleam/list
import lustre/effect.{type Effect}
@target(javascript)
import page_context.{type PageContext}

@target(javascript)
pub fn load_client(
  page_context page_context: PageContext,
  query_params query_params: page_input.QueryParams,
  route route: routes.Route,
) -> #(pages.Page, Effect(pages.Message)) {
  #(pages.load_sync(page_context, query_params, route), request_effect(route))
}

@target(javascript)
fn request_effect(route: routes.Route) -> Effect(pages.Message) {
  case route {
    routes.AdminHome | routes.AdminGames ->
      client_transport.send_admin_games_load(
        message: admin_games_page.AdminGamesLoad,
        on_result: fn(result) { load_result_message(route, result) },
      )
    routes.NotFound -> effect.none()
  }
}

@target(javascript)
pub fn load_result_message(
  route: routes.Route,
  result: Result(admin_games_page.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.AdminHome, Ok(admin_games_page.AdminGamesLoadResult(games)) ->
      pages.AdminHomeMsg(admin_games_page.Loaded(Ok(games)))
    routes.AdminGames, Ok(admin_games_page.AdminGamesLoadResult(games)) ->
      pages.AdminGamesMsg(admin_games_page.Loaded(Ok(games)))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected admin load response.")
  }
}

@target(javascript)
fn load_error_message(route: routes.Route, message: String) -> pages.Message {
  case route {
    routes.AdminHome ->
      pages.AdminHomeMsg(
        admin_games_page.Loaded(Error(admin_games_page.LoadError(message:))),
      )
    routes.AdminGames ->
      pages.AdminGamesMsg(
        admin_games_page.Loaded(Error(admin_games_page.LoadError(message:))),
      )
    routes.NotFound ->
      pages.AdminGamesMsg(
        admin_games_page.Loaded(Error(admin_games_page.LoadError(message:))),
      )
  }
}

@target(javascript)
fn api_load_error(errors: List(wire_result.ApiLoadError)) -> String {
  case errors {
    [wire_result.ApiLoadError(message: message), ..] -> message
    [] -> "Could not load page."
  }
}

pub fn apply_message(
  page page: pages.Page,
  message _message: ToClient,
) -> #(pages.Page, Effect(pages.Message)) {
  #(page, effect.none())
}

pub fn apply_broadcast(
  page page: pages.Page,
  message message: broadcasts.Event,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.AdminHomePage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        admin_games_page.game_updated(model, admin_game_update(game))
      #(pages.AdminHomePage(model), effect.map(page_effect, pages.AdminHomeMsg))
    }
    pages.AdminGamesPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        admin_games_page.game_updated(model, admin_game_update(game))
      #(
        pages.AdminGamesPage(model),
        effect.map(page_effect, pages.AdminGamesMsg),
      )
    }
    _, _ -> #(page, effect.none())
  }
}

pub fn apply_messages(
  page page: pages.Page,
  messages messages: List(ToClient),
) -> pages.Page {
  list.fold(messages, page, fn(page, message) {
    let #(page, _) = apply_message(page: page, message: message)
    page
  })
}

fn admin_game_update(
  game: broadcasts.GameSnapshot,
) -> admin_games_page.GameUpdate {
  let broadcasts.BroadcastGameSnapshot(
    id:,
    home: broadcasts.BroadcastTeam(code: home_code, ..),
    away: broadcasts.BroadcastTeam(code: away_code, ..),
    home_score:,
    away_score:,
    status:,
  ) = game

  admin_games_page.AdminGamesUpdate(
    id:,
    home_code:,
    away_code:,
    home_score:,
    away_score:,
    status: admin_game_status(status),
  )
}

fn admin_game_status(
  status: broadcasts.GameStatus,
) -> admin_games_page.GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> admin_games_page.AdminGamesScheduled
    broadcasts.BroadcastLive(period) -> admin_games_page.AdminGamesLive(period)
    broadcasts.BroadcastFinal -> admin_games_page.AdminGamesFinal
  }
}
