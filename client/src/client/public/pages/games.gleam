//// Client public games-list page.
////
//// Owns the page model, Msg type, and constructor-named ToClient handlers
//// for the public games route. Shared page modules keep target-neutral view code.

import lustre/effect.{type Effect}
import shared/api/domain/game.{
  type GameSnapshot, type PublicGameSummary, PublicGameSummary,
}

pub type Model {
  Model(games: List(PublicGameSummary), notice: String)
}

pub type Msg {
  NoOp
}

pub fn init() -> Model {
  Model(games: [], notice: "")
}

// nolint: label_possible, redundant_case -- model/msg is the standard TEA signature. Single-branch case is future-proof for browser events.
pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    NoOp -> #(model, effect.none())
  }
}

pub fn games_loaded(
  model _model: Model,
  games games: List(PublicGameSummary),
) -> #(Model, Effect(Msg)) {
  #(Model(games:, notice: ""), effect.none())
}

pub fn game_created(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(..model, games: upsert_game(games: model.games, snapshot: game)),
    effect.none(),
  )
}

pub fn game_updated(
  model model: Model,
  game game: GameSnapshot,
) -> #(Model, Effect(Msg)) {
  #(
    Model(..model, games: update_game(games: model.games, snapshot: game)),
    effect.none(),
  )
}

pub fn games_load_failed(
  model model: Model,
  reason reason: String,
) -> #(Model, Effect(Msg)) {
  #(Model(..model, notice: reason), effect.none())
}

fn upsert_game(
  games games: List(PublicGameSummary),
  snapshot snapshot: GameSnapshot,
) -> List(PublicGameSummary) {
  upsert_game_summary(games: games, snapshot: snapshot, seen: False)
}

fn upsert_game_summary(
  games games: List(PublicGameSummary),
  snapshot snapshot: GameSnapshot,
  seen seen: Bool,
) -> List(PublicGameSummary) {
  case games {
    [] -> {
      case seen {
        True -> []
        False -> [snapshot_to_summary(snapshot)]
      }
    }
    [game, ..rest] -> {
      case game.id == snapshot.id {
        True -> [
          snapshot_to_summary(snapshot),
          ..upsert_game_summary(games: rest, snapshot:, seen: True)
        ]
        False -> [game, ..upsert_game_summary(games: rest, snapshot:, seen:)]
      }
    }
  }
}

fn update_game(
  games games: List(PublicGameSummary),
  snapshot snapshot: GameSnapshot,
) -> List(PublicGameSummary) {
  case games {
    [] -> []
    [game, ..rest] -> {
      case game.id == snapshot.id {
        True -> [snapshot_to_summary(snapshot), ..rest]
        False -> [game, ..update_game(games: rest, snapshot:)]
      }
    }
  }
}

fn snapshot_to_summary(snapshot: GameSnapshot) -> PublicGameSummary {
  PublicGameSummary(
    id: snapshot.id,
    home: snapshot.home,
    away: snapshot.away,
    home_score: snapshot.home_score,
    away_score: snapshot.away_score,
    status: snapshot.status,
  )
}
