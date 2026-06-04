@target(erlang)
import api/domain/game
@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server
@target(erlang)
import app_api
@target(erlang)
import app_topics
@target(erlang)
import app_ws
import authentication_context
@target(erlang)
import gleam/dynamic/decode
@target(erlang)
import gleam/erlang/atom
@target(erlang)
import gleam/erlang/process
@target(erlang)
import gleam/list
import gleam/option.{None, Some}
@target(erlang)
import gleam/result
import gleeunit
import gleeunit/should
@target(erlang)
import sqlight

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn normalize_email_test() {
  authentication_context.normalize_email(" Admin@Example.COM ")
  |> should.equal("admin@example.com")
}

pub fn normalize_display_name_test() {
  authentication_context.normalize_display_name(" Fan ")
  |> should.equal(Some("Fan"))

  authentication_context.normalize_display_name(" ")
  |> should.equal(None)
}

@target(erlang)
pub fn mark_final_returns_save_ack_payload_and_game_update_test() {
  let db = live_game_db()

  let reply =
    app_api.dispatch_reply(
      db: db,
      message: to_server.MarkFinal(1),
      admin_authorized: True,
    )

  case reply {
    app_api.SaveReply(
      result: Ok(to_client.GameUpdated(result)),
      messages: [to_client.GameUpdated(updated)],
    ) -> result.status == game.Final && updated.status == game.Final
    _ -> False
  }
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
pub fn update_score_returns_save_ack_payload_and_game_update_test() {
  let db = final_game_db()

  let reply =
    app_api.dispatch_reply(
      db: db,
      message: to_server.UpdateScore(1, 5, 2, "Live"),
      admin_authorized: True,
    )

  case reply {
    app_api.SaveReply(
      result: Ok(to_client.GameUpdated(result)),
      messages: [to_client.GameUpdated(updated)],
    ) ->
      result.status == game.Live("Live") && updated.status == game.Live("Live")
    _ -> False
  }
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
pub fn only_game_updates_are_global_mutation_broadcasts_test() {
  let game_update =
    to_client.GameUpdated(game.GameSnapshot(
      id: 1,
      home: game.Team("TOR", "Toronto Towers", "toronto-towers"),
      away: game.Team("MTL", "Montreal Meteors", "montréal-meteors"),
      home_score: 4,
      away_score: 2,
      status: game.Final,
    ))

  app_ws.should_broadcast_live_update(
    request: to_server.MarkFinal(1),
    reply: game_update,
  )
  |> should.equal(True)

  let games_loaded =
    to_client.GamesLoaded([
      game.PublicGameSummary(
        id: 1,
        home: game.Team("TOR", "Toronto Towers", "toronto-towers"),
        away: game.Team("MTL", "Montreal Meteors", "montréal-meteors"),
        home_score: 4,
        away_score: 2,
        status: game.Final,
      ),
    ])

  app_ws.should_broadcast_live_update(
    request: to_server.MarkFinal(1),
    reply: games_loaded,
  )
  |> should.equal(False)
}

@target(erlang)
pub fn app_topics_broadcasts_to_self_test() {
  process.flush_messages()
  app_topics.start()
  app_topics.join("self-test")

  let frame = <<"hello">>
  let selector =
    process.new_selector()
    |> process.select_record(
      tag: atom.create("scoreboard_frame"),
      fields: 1,
      mapping: fn(msg) {
        msg
        |> decode.run(decode.at([1], decode.bit_array))
        |> result.unwrap(<<>>)
      },
    )

  app_topics.broadcast("self-test", frame)

  process.selector_receive(selector, within: 1000)
  |> should.equal(Ok(frame))
}

@target(erlang)
pub fn app_topics_can_exclude_self_test() {
  process.flush_messages()
  app_topics.start()
  app_topics.join("self-excluded-test")

  let frame = <<"hello">>
  let selector =
    process.new_selector()
    |> process.select_record(
      tag: atom.create("scoreboard_frame"),
      fields: 1,
      mapping: fn(msg) {
        msg
        |> decode.run(decode.at([1], decode.bit_array))
        |> result.unwrap(<<>>)
      },
    )

  app_topics.broadcast_except_self("self-excluded-test", frame)

  process.selector_receive(selector, within: 100)
  |> should.equal(Error(Nil))
}

@target(erlang)
pub fn load_standings_returns_only_standings_test() {
  let db = live_game_db()

  let replies =
    app_api.dispatch(
      db: db,
      message: to_server.LoadStandings,
      admin_authorized: False,
    )

  case replies {
    [to_client.StandingsLoaded(rows)] -> list.length(rows)
    _ -> 0
  }
  |> should.equal(2)

  replies
  |> has_toronto_standing(wins: 0, losses: 0, points_for: 0, points_against: 0)
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
fn has_toronto_standing(
  messages: List(ToClient),
  wins wins: Int,
  losses losses: Int,
  points_for points_for: Int,
  points_against points_against: Int,
) -> Bool {
  list.any(messages, fn(message) {
    case message {
      to_client.StandingsLoaded(rows) ->
        list.any(rows, fn(row) {
          row.team_code == "TOR"
          && row.wins == wins
          && row.losses == losses
          && row.points_for == points_for
          && row.points_against == points_against
        })
      _ -> False
    }
  })
}

@target(erlang)
fn live_game_db() -> sqlight.Connection {
  test_db_with_game(period: "3rd", final: "0")
}

@target(erlang)
fn final_game_db() -> sqlight.Connection {
  test_db_with_game(period: "Final", final: "1")
}

@target(erlang)
fn test_db_with_game(
  period period: String,
  final final: String,
) -> sqlight.Connection {
  let assert Ok(db) = sqlight.open("file:scoreboard_test?mode=memory")
  let assert Ok(_) = sqlight.exec("
      CREATE TABLE teams (
        code TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL
      );

      CREATE TABLE games (
        id INTEGER PRIMARY KEY,
        home_code TEXT NOT NULL REFERENCES teams (code),
        away_code TEXT NOT NULL REFERENCES teams (code),
        home_score INTEGER NOT NULL DEFAULT 0,
        away_score INTEGER NOT NULL DEFAULT 0,
        period TEXT NOT NULL DEFAULT 'Scheduled',
        final INTEGER NOT NULL DEFAULT 0,
        CHECK (home_code <> away_code),
        CHECK (final IN (0, 1))
      );

      INSERT INTO teams (code, name, slug)
      VALUES
        ('TOR', 'Toronto Towers', 'toronto-towers'),
        ('MTL', 'Montreal Meteors', 'montreal-meteors');

      INSERT INTO games (
        id,
        home_code,
        away_code,
        home_score,
        away_score,
        period,
        final
      )
      VALUES (1, 'TOR', 'MTL', 4, 2, '" <> period <> "', " <> final <> ");
      ", on: db)
  db
}
