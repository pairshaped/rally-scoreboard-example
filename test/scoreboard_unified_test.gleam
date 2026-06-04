@target(erlang)
import admin/pages/games as admin_games_page
@target(erlang)
import app_api
@target(erlang)
import app_topics
import authentication_context
@target(erlang)
import broadcasts
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
import public/pages/standings as public_standings_page
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

  let result =
    admin_games_page.handle(db, admin_games_page.AdminGamesMarkFinal(1))
  let broadcast = app_api.game_updated_broadcast(db, 1)

  case result, broadcast {
    Ok(admin_games_page.AdminGamesUpdate(
      status: admin_games_page.AdminGamesFinal,
      ..,
    )),
      Ok(broadcasts.BroadcastGameUpdated(updated))
    -> updated.status == broadcasts.BroadcastFinal
    _, _ -> False
  }
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
pub fn update_score_returns_save_ack_payload_and_game_update_test() {
  let db = final_game_db()

  let result =
    admin_games_page.handle(
      db,
      admin_games_page.AdminGamesUpdateScore(1, 5, 2, "Live"),
    )
  let broadcast = app_api.game_updated_broadcast(db, 1)

  case result, broadcast {
    Ok(admin_games_page.AdminGamesUpdate(
      status: admin_games_page.AdminGamesLive("Live"),
      ..,
    )),
      Ok(broadcasts.BroadcastGameUpdated(updated))
    -> updated.status == broadcasts.BroadcastLive("Live")
    _, _ -> False
  }
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
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
pub fn load_standings_returns_page_owned_game_summaries_test() {
  let db = live_game_db()

  let result = public_standings_page.load(db)

  case result {
    Ok(games) -> list.length(games)
    _ -> 0
  }
  |> should.equal(1)

  result
  |> has_toronto_game_summary(home_score: 4, away_score: 2)
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
fn has_toronto_game_summary(
  result: Result(
    List(public_standings_page.GameSummary),
    public_standings_page.LoadError,
  ),
  home_score home_score: Int,
  away_score away_score: Int,
) -> Bool {
  case result {
    Ok(games) ->
      list.any(games, fn(game) {
        game.home.code == "TOR"
        && game.home_score == home_score
        && game.away_score == away_score
      })
    Error(_) -> False
  }
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
