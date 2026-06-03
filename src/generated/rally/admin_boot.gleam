import admin/pages/games as admin_games_page
import api/domain/game as api_game
import api/to_client.{type ToClient}
import api/to_server.{type ToServer}
@target(javascript)
import generated/proute/admin/page_input
import generated/proute/admin/pages
import generated/proute/admin/routes
@target(javascript)
import generated/rally/client_transport
import gleam/list
import lustre/effect.{type Effect}
@target(javascript)
import page_context.{type PageContext}

pub fn requests(route: routes.Route) -> List(ToServer) {
  case route {
    routes.AdminHome | routes.AdminGames -> [to_server.LoadAdminGames]
    routes.NotFound -> []
  }
}

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
  route
  |> requests
  |> list.map(fn(request) {
    client_transport.send(module: request_module(route), message: request)
  })
  |> effect.batch
}

@target(javascript)
fn request_module(route: routes.Route) -> String {
  case route {
    routes.AdminHome | routes.AdminGames -> "admin/games"
    routes.NotFound -> ""
  }
}

pub fn apply_message(
  page page: pages.Page,
  message message: ToClient,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.AdminHomePage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, page_effect) =
        admin_games_page.admin_games_loaded(
          model,
          list.map(games, admin_game_summary),
        )
      #(pages.AdminHomePage(model), effect.map(page_effect, pages.AdminHomeMsg))
    }
    pages.AdminHomePage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        admin_games_page.game_updated(model, admin_game_update(game))
      #(pages.AdminHomePage(model), effect.map(page_effect, pages.AdminHomeMsg))
    }
    pages.AdminGamesPage(model), to_client.AdminGamesLoaded(games) -> {
      let #(model, page_effect) =
        admin_games_page.admin_games_loaded(
          model,
          list.map(games, admin_game_summary),
        )
      #(
        pages.AdminGamesPage(model),
        effect.map(page_effect, pages.AdminGamesMsg),
      )
    }
    pages.AdminGamesPage(model), to_client.GameUpdated(game) -> {
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

fn admin_game_summary(
  game: api_game.AdminGameSummary,
) -> admin_games_page.AdminGameSummary {
  admin_games_page.AdminGameSummary(
    id: game.id,
    home_code: game.home_code,
    away_code: game.away_code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: admin_game_status(game.status),
    needs_attention: game.needs_attention,
  )
}

fn admin_game_update(
  game: api_game.GameSnapshot,
) -> admin_games_page.GameUpdate {
  admin_games_page.GameUpdate(
    id: game.id,
    home_code: game.home.code,
    away_code: game.away.code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: admin_game_status(game.status),
  )
}

fn admin_game_status(
  status: api_game.GameStatus,
) -> admin_games_page.GameStatus {
  case status {
    api_game.Scheduled -> admin_games_page.Scheduled
    api_game.Live(period) -> admin_games_page.Live(period)
    api_game.Final -> admin_games_page.Final
  }
}
