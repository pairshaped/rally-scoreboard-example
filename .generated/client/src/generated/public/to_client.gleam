//// Generated. Do not edit.
////
//// Root API ToClient dispatch for the public Mount.
////
//// Derived from shared/api/to_client.gleam and client/public/pages.
////
//// ToClient is the server-event vocabulary. Server events are applied as page
//// mini-updates: each handler receives the page model plus constructor fields
//// and returns the updated page model plus any page effect.
////
//// Local page Msg is for browser-originated events only. Generated dispatch
//// owns page-model bundle plumbing and effect batching.

import client/public/pages/games
import client/public/pages/games/id_ as game_detail
import client/public/pages/standings
import client/public/pages/teams/slug_ as team
import lustre/effect.{type Effect}
import shared/api/to_client.{type ToClient}

pub type Models {
  Models(
    games_page: games.Model,
    game_detail_page: game_detail.Model,
    standings_page: standings.Model,
    team_page: team.Model,
  )
}

pub type Msg {
  GamesPage(games.Msg)
  GameDetailPage(game_detail.Msg)
  StandingsPage(standings.Msg)
  TeamPage(team.Msg)
}

pub fn init() -> Models {
  Models(
    games_page: games.init(),
    game_detail_page: game_detail.init(),
    standings_page: standings.init(),
    team_page: team.init(),
  )
}

pub fn apply_to_client(
  models models: Models,
  msg msg: ToClient,
) -> #(Models, Effect(Msg)) {
  case msg {
    to_client.GamesLoaded(games: games_list) -> {
      let #(page, eff) =
        games.games_loaded(models.games_page, games: games_list)
      #(Models(..models, games_page: page), effect.map(eff, GamesPage))
    }
    to_client.GameLoaded(game: game) -> {
      let #(page, eff) = game_detail.game_loaded(models.game_detail_page, game:)
      #(
        Models(..models, game_detail_page: page),
        effect.map(eff, GameDetailPage),
      )
    }
    to_client.StandingsLoaded(rows: rows) -> {
      let #(page, eff) =
        standings.standings_loaded(models.standings_page, rows:)
      #(Models(..models, standings_page: page), effect.map(eff, StandingsPage))
    }
    to_client.PowerRankingsLoaded(rows: rows) -> {
      let #(page, eff) =
        standings.power_rankings_loaded(models.standings_page, rows:)
      #(Models(..models, standings_page: page), effect.map(eff, StandingsPage))
    }
    to_client.GameUpdated(game: game) -> {
      let #(games_page, games_eff) =
        games.game_updated(models.games_page, game:)
      let #(game_detail_page, detail_eff) =
        game_detail.game_updated(models.game_detail_page, game:)
      let #(team_page, team_eff) = team.game_updated(models.team_page, game:)
      #(
        Models(..models, games_page:, game_detail_page:, team_page:),
        effect.batch([
          effect.map(games_eff, GamesPage),
          effect.map(detail_eff, GameDetailPage),
          effect.map(team_eff, TeamPage),
        ]),
      )
    }
    to_client.GamesLoadFailed(reason: reason) -> {
      let #(games_page, games_eff) =
        games.games_load_failed(models.games_page, reason:)
      let #(game_detail_page, detail_eff) =
        game_detail.games_load_failed(models.game_detail_page, reason:)
      let #(team_page, team_eff) =
        team.games_load_failed(models.team_page, reason:)
      #(
        Models(..models, games_page:, game_detail_page:, team_page:),
        effect.batch([
          effect.map(games_eff, GamesPage),
          effect.map(detail_eff, GameDetailPage),
          effect.map(team_eff, TeamPage),
        ]),
      )
    }
    to_client.TeamLoaded(team: team_detail) -> {
      let #(page, eff) = team.team_loaded(models.team_page, team: team_detail)
      #(Models(..models, team_page: page), effect.map(eff, TeamPage))
    }
    _ -> #(models, effect.none())
  }
}

pub fn update_page(
  models models: Models,
  msg msg: Msg,
) -> #(Models, Effect(Msg)) {
  case msg {
    GamesPage(page_msg) -> {
      let #(page, eff) = games.update(models.games_page, page_msg)
      #(Models(..models, games_page: page), effect.map(eff, GamesPage))
    }
    GameDetailPage(page_msg) -> {
      let #(page, eff) = game_detail.update(models.game_detail_page, page_msg)
      #(
        Models(..models, game_detail_page: page),
        effect.map(eff, GameDetailPage),
      )
    }
    StandingsPage(page_msg) -> {
      let #(page, eff) = standings.update(models.standings_page, page_msg)
      #(Models(..models, standings_page: page), effect.map(eff, StandingsPage))
    }
    TeamPage(page_msg) -> {
      let #(page, eff) = team.update(models.team_page, page_msg)
      #(Models(..models, team_page: page), effect.map(eff, TeamPage))
    }
  }
}
