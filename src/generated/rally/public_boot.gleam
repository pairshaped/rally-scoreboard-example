import api/domain/game as api_game
import api/to_client.{type ToClient}
@target(javascript)
import generated/libero/result as wire_result
@target(javascript)
import generated/proute/public/page_input
import generated/proute/public/pages
@target(javascript)
import generated/proute/public/routes
@target(javascript)
import generated/rally/client_transport
@target(javascript)
import gleam/int
import gleam/list
import lustre/effect.{type Effect}
@target(javascript)
import page_context.{type PageContext}
import public/pages/games as games_page
import public/pages/games/id_ as games_id_page
@target(javascript)
import public/pages/games/id_/wire as public_game_detail_wire
@target(javascript)
import public/pages/games/wire as public_games_wire
import public/pages/standings as standings_page
@target(javascript)
import public/pages/standings/wire as public_standings_wire
import public/pages/teams/slug_ as teams_slug_page
@target(javascript)
import public/pages/teams/slug_/wire as public_team_detail_wire

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
    routes.Home | routes.Games ->
      client_transport.send_public_games_load(on_result: fn(result) {
        public_games_load_result_message(route, result)
      })
    routes.GamesId(id) ->
      case int.parse(id) {
        Ok(game_id) ->
          client_transport.send_public_game_detail_load(
            game_id:,
            on_result: fn(result) {
              public_game_detail_load_result_message(route, result)
            },
          )
        Error(Nil) -> effect.none()
      }
    routes.Standings ->
      client_transport.send_public_standings_load(on_result: fn(result) {
        public_standings_load_result_message(route, result)
      })
    routes.TeamsSlug(slug) ->
      client_transport.send_public_team_detail_load(
        slug:,
        on_result: fn(result) {
          public_team_detail_load_result_message(route, result)
        },
      )
    routes.SignIn | routes.NotFound -> effect.none()
  }
}

@target(javascript)
pub fn public_games_load_result_message(
  route: routes.Route,
  result: Result(public_games_wire.LoadResult, List(wire_result.ApiLoadError)),
) -> pages.Message {
  case route, result {
    routes.Home, Ok(public_games_wire.PublicGamesLoaded(games)) ->
      pages.HomeMsg(
        games_page.Loaded(Ok(list.map(games, games_page.from_wire_summary))),
      )
    routes.Games, Ok(public_games_wire.PublicGamesLoaded(games)) ->
      pages.GamesMsg(
        games_page.Loaded(Ok(list.map(games, games_page.from_wire_summary))),
      )
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected public games response.")
  }
}

@target(javascript)
pub fn public_game_detail_load_result_message(
  route: routes.Route,
  result: Result(
    public_game_detail_wire.LoadResult,
    List(wire_result.ApiLoadError),
  ),
) -> pages.Message {
  case route, result {
    routes.GamesId(_), Ok(public_game_detail_wire.PublicGameDetailLoaded(game))
    ->
      pages.GamesIdMsg(
        games_id_page.Loaded(Ok(games_id_page.from_wire_detail(game))),
      )
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected game response.")
  }
}

@target(javascript)
pub fn public_standings_load_result_message(
  route: routes.Route,
  result: Result(
    public_standings_wire.LoadResult,
    List(wire_result.ApiLoadError),
  ),
) -> pages.Message {
  case route, result {
    routes.Standings, Ok(public_standings_wire.PublicStandingsLoaded(games)) ->
      pages.StandingsMsg(
        standings_page.Loaded(
          Ok(list.map(games, standings_page.from_wire_summary)),
        ),
      )
    _, Error(errors) -> load_error_message(route, api_load_error(errors))
    _, Ok(_) -> load_error_message(route, "Unexpected standings response.")
  }
}

@target(javascript)
pub fn public_team_detail_load_result_message(
  route: routes.Route,
  result: Result(
    public_team_detail_wire.LoadResult,
    List(wire_result.ApiLoadError),
  ),
) -> pages.Message {
  case route, result {
    routes.TeamsSlug(_),
      Ok(public_team_detail_wire.PublicTeamDetailLoaded(team))
    ->
      pages.TeamsSlugMsg(
        teams_slug_page.Loaded(Ok(teams_slug_page.from_wire_detail(team))),
      )
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

pub fn apply_message(
  page page: pages.Page,
  message message: ToClient,
) -> #(pages.Page, Effect(pages.Message)) {
  case page, message {
    pages.HomePage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.HomePage(model), effect.map(page_effect, pages.HomeMsg))
    }
    pages.GamesPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_page.game_updated(model, public_game_update(game))
      #(pages.GamesPage(model), effect.map(page_effect, pages.GamesMsg))
    }
    pages.GamesIdPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        games_id_page.game_updated(model, detail_game_update(game))
      #(pages.GamesIdPage(model), effect.map(page_effect, pages.GamesIdMsg))
    }
    pages.StandingsPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        standings_page.game_updated(model, standings_game_update(game))
      #(pages.StandingsPage(model), effect.map(page_effect, pages.StandingsMsg))
    }
    pages.TeamsSlugPage(model), to_client.GameUpdated(game) -> {
      let #(model, page_effect) =
        teams_slug_page.game_updated(model, team_game_update(game))
      #(pages.TeamsSlugPage(model), effect.map(page_effect, pages.TeamsSlugMsg))
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

fn public_game_update(game: api_game.GameSnapshot) -> games_page.GameUpdate {
  games_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: public_game_status(game.status),
  )
}

fn public_game_status(status: api_game.GameStatus) -> games_page.GameStatus {
  case status {
    api_game.Scheduled -> games_page.Scheduled
    api_game.Live(period) -> games_page.Live(period)
    api_game.Final -> games_page.Final
  }
}

fn detail_game_update(game: api_game.GameSnapshot) -> games_id_page.GameUpdate {
  games_id_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: detail_game_status(game.status),
  )
}

fn detail_game_status(status: api_game.GameStatus) -> games_id_page.GameStatus {
  case status {
    api_game.Scheduled -> games_id_page.Scheduled
    api_game.Live(period) -> games_id_page.Live(period)
    api_game.Final -> games_id_page.Final
  }
}

fn standings_game_update(
  game: api_game.GameSnapshot,
) -> standings_page.GameUpdate {
  standings_page.GameUpdate(
    id: game.id,
    home_score: game.home_score,
    away_score: game.away_score,
    status: standings_game_status(game.status),
  )
}

fn standings_game_status(
  status: api_game.GameStatus,
) -> standings_page.GameStatus {
  case status {
    api_game.Scheduled -> standings_page.Scheduled
    api_game.Live(period) -> standings_page.Live(period)
    api_game.Final -> standings_page.Final
  }
}

fn team_game_update(game: api_game.GameSnapshot) -> teams_slug_page.GameUpdate {
  teams_slug_page.GameUpdate(
    id: game.id,
    home_code: game.home.code,
    away_code: game.away.code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: team_game_status(game.status),
  )
}

fn team_game_status(status: api_game.GameStatus) -> teams_slug_page.GameStatus {
  case status {
    api_game.Scheduled -> teams_slug_page.Scheduled
    api_game.Live(period) -> teams_slug_page.Live(period)
    api_game.Final -> teams_slug_page.Final
  }
}
