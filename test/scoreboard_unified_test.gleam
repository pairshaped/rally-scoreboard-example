@target(erlang)
import api/to_client.{type ToClient}
@target(erlang)
import api/to_server
import authentication_context
@target(erlang)
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
@target(erlang)
import server/api
@target(erlang)
import server/ws
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
pub fn mark_final_returns_fresh_standings_test() {
  let db = live_game_db()

  api.dispatch(db: db, message: to_server.MarkFinal(1), admin_authorized: True)
  |> has_toronto_standing(wins: 1, losses: 0, points_for: 4, points_against: 2)
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
pub fn update_score_on_final_game_returns_fresh_standings_test() {
  let db = final_game_db()

  api.dispatch(
    db: db,
    message: to_server.UpdateScore(1, 5, 2, "Live"),
    admin_authorized: True,
  )
  |> has_toronto_standing(wins: 0, losses: 0, points_for: 0, points_against: 0)
  |> should.equal(True)

  let assert Ok(_) = sqlight.close(db)
}

@target(erlang)
pub fn final_standings_are_mutation_broadcasts_test() {
  let standings = to_client.StandingsLoaded([])

  ws.should_broadcast_live_update(
    request: to_server.MarkFinal(1),
    reply: standings,
  )
  |> should.equal(True)

  ws.should_broadcast_live_update(
    request: to_server.UpdateScore(1, 5, 2, "Live"),
    reply: standings,
  )
  |> should.equal(True)

  ws.should_broadcast_live_update(
    request: to_server.LoadStandings,
    reply: standings,
  )
  |> should.equal(False)
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
