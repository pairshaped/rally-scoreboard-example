//// Client admin games page.
////
//// Owns the page model, Msg type, page-local effects, and constructor-named
//// ToClient handlers for the admin games route. Shared page modules keep
//// target-neutral view code.

import generated/runtime/effect as client_effect
import gleam/bool
import gleam/dict
import gleam/string
import lustre/effect.{type Effect}
import shared/api/domain/game.{
  type AdminGameDetail, type AdminGameSummary, type GameSnapshot,
  AdminGameSummary,
}
import shared/api/to_server

pub type Model {
  Model(
    games: List(AdminGameSummary),
    notice: String,
    home_code: String,
    away_code: String,
  )
}

pub type Msg {
  CreateGame
  UpdateHomeCode(String)
  UpdateAwayCode(String)
  AdjustHome(Int, Int, Int, Int)
  AdjustAway(Int, Int, Int, Int)
  MarkFinal(Int)
}

pub fn init() -> Model {
  Model(games: [], notice: "", home_code: "TOR", away_code: "NYC")
}

// nolint: label_possible -- model/msg is the standard TEA signature.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UpdateHomeCode(value) -> #(
      Model(..model, home_code: string.uppercase(string.trim(value))),
      effect.none(),
    )
    UpdateAwayCode(value) -> #(
      Model(..model, away_code: string.uppercase(string.trim(value))),
      effect.none(),
    )
    CreateGame -> #(
      Model(..model, notice: "Creating game..."),
      send_admin_games_command(to_server.CreateGame(
        home_code: model.home_code,
        away_code: model.away_code,
      )),
    )
    AdjustHome(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      send_admin_games_command(to_server.UpdateScore(
        game_id:,
        home_score: clamp_score(home_score + delta),
        away_score:,
        period: "4th",
      )),
    )
    AdjustAway(game_id, home_score, away_score, delta) -> #(
      Model(..model, notice: "Saving score..."),
      send_admin_games_command(to_server.UpdateScore(
        game_id:,
        home_score:,
        away_score: clamp_score(away_score + delta),
        period: "4th",
      )),
    )
    MarkFinal(game_id) -> #(
      Model(..model, notice: "Marking final..."),
      send_admin_games_command(to_server.MarkFinal(game_id:)),
    )
  }
}

pub fn admin_games_loaded(
  model model: Model,
  games games: List(AdminGameSummary),
) -> #(Model, Effect(Msg)) {
  #(Model(..model, games:, notice: ""), effect.none())
}

pub fn game_created(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      games: upsert_game_summary(
        games: model.games,
        summary: snapshot_to_admin_summary(game),
        seen: False,
      ),
      notice: "Game created.",
    ),
    effect.none(),
  )
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      games: upsert_game_summary(
        games: model.games,
        summary: snapshot_to_admin_summary(game),
        seen: False,
      ),
    ),
    effect.none(),
  )
}

pub fn score_update_saved(
  model model: Model,
  game game: AdminGameDetail,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      games: upsert_game(games: model.games, detail: game),
      notice: "Saved.",
    ),
    effect.none(),
  )
}

pub fn result_saved(
  model model: Model,
  game game: AdminGameDetail,
) -> #(Model, Effect(Msg)) {
  #(
    Model(
      ..model,
      games: upsert_game(games: model.games, detail: game),
      notice: "Result saved.",
    ),
    effect.none(),
  )
}

pub fn admin_error(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}

fn send_admin_games_command(command: to_server.ToServer) -> Effect(Msg) {
  client_effect.send_page_init_and_command(
    module: "AdminGames",
    params: "null",
    query: dict.new(),
    command:,
  )
}

fn clamp_score(score: Int) -> Int {
  use <- bool.guard(when: score < 0, return: 0)
  score
}

fn upsert_game(
  games games: List(AdminGameSummary),
  detail detail: AdminGameDetail,
) -> List(AdminGameSummary) {
  upsert_game_summary(
    games:,
    summary: admin_detail_to_summary(detail),
    seen: False,
  )
}

fn upsert_game_summary(
  games games: List(AdminGameSummary),
  summary summary: AdminGameSummary,
  seen seen: Bool,
) -> List(AdminGameSummary) {
  case games {
    [] -> {
      case seen {
        True -> []
        False -> [summary]
      }
    }
    [game, ..rest] -> {
      case game.id == summary.id {
        True -> [
          summary,
          ..upsert_game_summary(games: rest, summary:, seen: True)
        ]
        False -> [game, ..upsert_game_summary(games: rest, summary:, seen:)]
      }
    }
  }
}

fn admin_detail_to_summary(game: AdminGameDetail) -> AdminGameSummary {
  AdminGameSummary(
    id: game.id,
    home_code: game.home_code,
    away_code: game.away_code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
    needs_attention: False,
  )
}

fn snapshot_to_admin_summary(game: GameSnapshot) -> AdminGameSummary {
  AdminGameSummary(
    id: game.id,
    home_code: game.home.code,
    away_code: game.away.code,
    home_score: game.home_score,
    away_score: game.away_score,
    status: game.status,
    needs_attention: False,
  )
}
