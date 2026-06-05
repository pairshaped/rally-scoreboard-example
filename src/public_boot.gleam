import broadcasts
import generated/proute/public/pages
import generated/proute/public/routes
import lustre/effect.{type Effect}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
import public/pages/standings as standings_page
import public/pages/teams/slug_ as teams_slug_page

@target(erlang)
import generated/rally/server_ssr

@target(javascript)
import generated/rally/browser_app
@target(javascript)
import generated/rally/result as wire_result
@target(javascript)
import gleam/int

@target(javascript)
pub fn load_route(route: routes.Route) -> browser_app.PublicLoadRoute {
  case route {
    routes.Home | routes.Games ->
      browser_app.PublicGamesLoad(
        message: games_page.PublicGamesLoad,
        to_message: fn(result) {
          public_games_load_result_message(route, result)
        },
      )
    routes.GamesId(game_id) ->
      case int.parse(game_id) {
        Ok(game_id) ->
          browser_app.PublicGameDetailLoad(
            message: games_id_page.PublicGameDetailLoad(game_id:),
            to_message: fn(result) {
              public_game_detail_load_result_message(route, result)
            },
          )
        Error(Nil) -> browser_app.PublicNoLoad
      }
    routes.Standings ->
      browser_app.PublicStandingsLoad(
        message: standings_page.PublicStandingsLoad,
        to_message: fn(result) {
          public_standings_load_result_message(route, result)
        },
      )
    routes.TeamsSlug(slug) ->
      browser_app.PublicTeamDetailLoad(
        message: teams_slug_page.PublicTeamDetailLoad(slug:),
        to_message: fn(result) {
          public_team_detail_load_result_message(route, result)
        },
      )
    routes.SignIn | routes.NotFound -> browser_app.PublicNoLoad
  }
}

@target(erlang)
pub fn ssr_load_route(route: routes.Route) -> server_ssr.PublicLoadRoute {
  case route {
    routes.Home ->
      server_ssr.PublicGamesLoad(to_message: fn(result) {
        pages.HomeMsg(games_page.loaded_from_wire(result))
      })
    routes.Games ->
      server_ssr.PublicGamesLoad(to_message: fn(result) {
        pages.GamesMsg(games_page.loaded_from_wire(result))
      })
    routes.GamesId(_) ->
      server_ssr.PublicGameDetailLoad(to_message: fn(result) {
        pages.GamesIdMsg(games_id_page.loaded_from_wire(result))
      })
    routes.Standings ->
      server_ssr.PublicStandingsLoad(to_message: fn(result) {
        pages.StandingsMsg(standings_page.loaded_from_wire(result))
      })
    routes.TeamsSlug(_) ->
      server_ssr.PublicTeamDetailLoad(to_message: fn(result) {
        pages.TeamsSlugMsg(teams_slug_page.loaded_from_wire(result))
      })
    routes.SignIn | routes.NotFound -> server_ssr.PublicNoLoad
  }
}

@target(javascript)
pub fn public_games_load_result_message(
  route: routes.Route,
  result: Result(games_page.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.Home, Ok(games_page.PublicGamesLoaded(games)) ->
      pages.HomeMsg(games_page.Loaded(Ok(games)))
    routes.Games, Ok(games_page.PublicGamesLoaded(games)) ->
      pages.GamesMsg(games_page.Loaded(Ok(games)))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected public games response.")
  }
}

@target(javascript)
pub fn public_game_detail_load_result_message(
  route: routes.Route,
  result: Result(games_id_page.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.GamesId(_), Ok(games_id_page.PublicGameDetailLoaded(game)) ->
      pages.GamesIdMsg(games_id_page.Loaded(Ok(game)))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected game response.")
  }
}

@target(javascript)
pub fn public_standings_load_result_message(
  route: routes.Route,
  result: Result(standings_page.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.Standings, Ok(standings_page.PublicStandingsLoaded(games)) ->
      pages.StandingsMsg(standings_page.Loaded(Ok(games)))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected standings response.")
  }
}

@target(javascript)
pub fn public_team_detail_load_result_message(
  route: routes.Route,
  result: Result(teams_slug_page.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.TeamsSlug(_), Ok(teams_slug_page.PublicTeamDetailLoaded(team)) ->
      pages.TeamsSlugMsg(teams_slug_page.Loaded(Ok(team)))
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected team response.")
  }
}

@target(javascript)
fn load_error_message(route: routes.Route, message: String) -> pages.Message {
  case route {
    routes.Home ->
      pages.HomeMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
    routes.Games ->
      pages.GamesMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
    routes.GamesId(_) ->
      pages.GamesIdMsg(
        games_id_page.Loaded(Error(games_id_page.LoadError(message:))),
      )
    routes.Standings ->
      pages.StandingsMsg(
        standings_page.Loaded(Error(standings_page.LoadError(message:))),
      )
    routes.TeamsSlug(_) ->
      pages.TeamsSlugMsg(
        teams_slug_page.Loaded(Error(teams_slug_page.LoadError(message:))),
      )
    routes.SignIn | routes.NotFound ->
      pages.GamesMsg(games_page.Loaded(Error(games_page.LoadError(message:))))
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
    pages.HomePage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.GamesPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesIdPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        games_id_page.game_updated(model, detail_game_update(game))
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.StandingsPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        standings_page.game_updated(model, standings_game_update(game))
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.TeamsSlugPage(model), broadcasts.BroadcastGameUpdated(game) -> {
      let #(model, page_effect) =
        teams_slug_page.game_updated(model, team_game_update(game))
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
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

fn public_game_update(game: broadcasts.GameSnapshot) -> games_page.GameUpdate {
  let broadcasts.BroadcastGameSnapshot(
    id:,
    home_score:,
    away_score:,
    status:,
    ..,
  ) = game

  games_page.GameUpdate(
    id:,
    home_score:,
    away_score:,
    status: public_game_status(status),
  )
}

fn public_game_status(status: broadcasts.GameStatus) -> games_page.GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> games_page.Scheduled
    broadcasts.BroadcastLive(period) -> games_page.Live(period)
    broadcasts.BroadcastFinal -> games_page.Final
  }
}

fn detail_game_update(
  game: broadcasts.GameSnapshot,
) -> games_id_page.GameUpdate {
  let broadcasts.BroadcastGameSnapshot(
    id:,
    home_score:,
    away_score:,
    status:,
    ..,
  ) = game

  games_id_page.GameUpdate(
    id:,
    home_score:,
    away_score:,
    status: detail_game_status(status),
  )
}

fn detail_game_status(
  status: broadcasts.GameStatus,
) -> games_id_page.GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> games_id_page.Scheduled
    broadcasts.BroadcastLive(period) -> games_id_page.Live(period)
    broadcasts.BroadcastFinal -> games_id_page.Final
  }
}

fn standings_game_update(
  game: broadcasts.GameSnapshot,
) -> standings_page.GameUpdate {
  let broadcasts.BroadcastGameSnapshot(
    id:,
    home_score:,
    away_score:,
    status:,
    ..,
  ) = game

  standings_page.GameUpdate(
    id:,
    home_score:,
    away_score:,
    status: standings_game_status(status),
  )
}

fn standings_game_status(
  status: broadcasts.GameStatus,
) -> standings_page.GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> standings_page.Scheduled
    broadcasts.BroadcastLive(period) -> standings_page.Live(period)
    broadcasts.BroadcastFinal -> standings_page.Final
  }
}

fn team_game_update(
  game: broadcasts.GameSnapshot,
) -> teams_slug_page.GameUpdate {
  let broadcasts.BroadcastGameSnapshot(
    id:,
    home: broadcasts.BroadcastTeam(code: home_code, ..),
    away: broadcasts.BroadcastTeam(code: away_code, ..),
    home_score:,
    away_score:,
    status:,
  ) = game

  teams_slug_page.GameUpdate(
    id:,
    home_code:,
    away_code:,
    home_score:,
    away_score:,
    status: team_game_status(status),
  )
}

fn team_game_status(
  status: broadcasts.GameStatus,
) -> teams_slug_page.GameStatus {
  case status {
    broadcasts.BroadcastScheduled -> teams_slug_page.Scheduled
    broadcasts.BroadcastLive(period) -> teams_slug_page.Live(period)
    broadcasts.BroadcastFinal -> teams_slug_page.Final
  }
}
