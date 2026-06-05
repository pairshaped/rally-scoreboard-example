import admin/pages/games as admin_games_page
import broadcasts
import generated/proute/admin/pages
import generated/proute/admin/routes
import lustre/effect.{type Effect}

@target(erlang)
import generated/rally/server_ssr

@target(javascript)
import generated/rally/browser_app
@target(javascript)
import generated/rally/result as wire_result

@target(javascript)
pub fn load_route(route: routes.Route) -> browser_app.AdminLoadRoute {
  case route {
    routes.AdminHome | routes.AdminGames ->
      browser_app.AdminGamesLoad(
        message: admin_games_page.AdminGamesLoad,
        to_message: fn(result) { load_result_message(route, result) },
      )
    routes.NotFound -> browser_app.AdminNoLoad
  }
}

@target(erlang)
pub fn ssr_load_route(route: routes.Route) -> server_ssr.AdminLoadRoute {
  case route {
    routes.AdminHome ->
      server_ssr.AdminGamesLoad(to_message: fn(result) {
        pages.AdminHomeMsg(admin_games_page.loaded_from_wire(result))
      })
    routes.AdminGames ->
      server_ssr.AdminGamesLoad(to_message: fn(result) {
        pages.AdminGamesMsg(admin_games_page.loaded_from_wire(result))
      })
    routes.NotFound -> server_ssr.AdminNoLoad
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

pub fn apply_push(
  page page: pages.Page,
  module module: String,
  message message: broadcasts.Event,
) -> #(pages.Page, Effect(pages.Message)) {
  case module {
    "app" -> apply_broadcast(page: page, message: message)
    _ -> #(page, effect.none())
  }
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
