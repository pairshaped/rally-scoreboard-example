import broadcasts
import generated/proute/public/pages
import lustre/effect.{type Effect}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
import public/pages/standings as standings_page
import public/pages/teams/slug_ as teams_slug_page

/// Page broadcast reducer used by browser push handling.
/// apply_push delegates app-channel broadcasts here after generated Rally decodes
/// the push frame.
pub fn apply_broadcast(
  page page: pages.Page,
  message message: broadcasts.Event,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.HomePage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.GamesPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) = games_page.game_updated(model, game)
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesIdPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) = games_id_page.game_updated(model, game)
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.StandingsPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) = standings_page.game_updated(model, game)
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.TeamsSlugPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) = teams_slug_page.game_updated(model, game)
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
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
