import admin/pages/games as admin_games_page
import broadcasts
import generated/proute/admin/pages
import lustre/effect.{type Effect}

/// Page broadcast reducer used by browser push handling.
/// apply_push delegates app-channel broadcasts here after generated Rally decodes
/// the push frame.
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

/// Push dispatcher passed to generated Rally browser_app.
/// It receives decoded push frames by module name and chooses which app-level
/// broadcast reducer should update the current Proute page.
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
