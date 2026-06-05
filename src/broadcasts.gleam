import gleam/int

@target(erlang)
import generated/sql/public/pages/games/id__sql as game_detail_sql
@target(erlang)
import sqlight

/// Typed broadcast topic.
/// Runtime websocket transport turns this into a pg group name at the boundary.
pub type Topic {
  AllGames
  AdminGames
  Game(id: Int)
  Team(slug: String)
}

/// Rally push payload with the topics that should receive it.
pub type TargetedEvent {
  TargetedEvent(topics: List(Topic), event: Event)
}

/// Rally push payload.
/// generated/rally push protocol and Libero codecs encode this when app_ws
/// broadcasts a server event to browser clients.
pub type Event {
  BroadcastGameUpdated(game: GameSnapshot)
}

/// Libero wire payload nested in GameSnapshot.
/// Browser boot code maps these broadcast statuses into page-local GameStatus
/// types before applying page update hooks.
pub type GameStatus {
  BroadcastScheduled
  BroadcastLive(period: String)
  BroadcastFinal
}

/// Libero wire payload nested in GameSnapshot.
/// Browser boot code maps these broadcast teams into page-local update types
/// before applying page update hooks.
pub type Team {
  BroadcastTeam(code: String, name: String, slug: String)
}

/// Rally push payload nested in Event.
/// Broadcast mapping builds this from the database after admin mutations, then
/// generated Rally protocol code carries it over the websocket.
pub type GameSnapshot {
  BroadcastGameSnapshot(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}

pub fn all_games_topic() -> Topic {
  AllGames
}

pub fn admin_games_topic() -> Topic {
  AdminGames
}

pub fn game_topic(id: Int) -> Topic {
  Game(id)
}

pub fn team_topic(slug: String) -> Topic {
  Team(slug)
}

pub fn topic_name(topic: Topic) -> String {
  case topic {
    AllGames -> "games"
    AdminGames -> "admin:games"
    Game(id) -> "game:" <> int.to_string(id)
    Team(slug) -> "team:" <> slug
  }
}

@target(erlang)
pub fn game_updated_broadcast(
  db: sqlight.Connection,
  game_id: Int,
) -> Result(TargetedEvent, Nil) {
  case game_detail_sql.get_game(db: db, game_id: game_id) {
    Ok([row, ..]) ->
      row
      |> game_updated_snapshot
      |> game_updated_targeted_event
      |> Ok
    _ -> Error(Nil)
  }
}

pub fn game_updated_targeted_event(game: GameSnapshot) -> TargetedEvent {
  TargetedEvent(
    topics: game_updated_topics(game),
    event: BroadcastGameUpdated(game),
  )
}

pub fn game_updated_topics(game: GameSnapshot) -> List(Topic) {
  let BroadcastGameSnapshot(
    id:,
    home: BroadcastTeam(slug: home_slug, ..),
    away: BroadcastTeam(slug: away_slug, ..),
    ..,
  ) = game

  [
    all_games_topic(),
    admin_games_topic(),
    game_topic(id),
    team_topic(home_slug),
    team_topic(away_slug),
  ]
}

@target(erlang)
fn game_updated_snapshot(row: game_detail_sql.GetGameRow) -> GameSnapshot {
  BroadcastGameSnapshot(
    id: row.id,
    home: BroadcastTeam(
      code: row.home_code,
      name: row.home_name,
      slug: row.home_slug,
    ),
    away: BroadcastTeam(
      code: row.away_code,
      name: row.away_name,
      slug: row.away_slug,
    ),
    home_score: row.home_score,
    away_score: row.away_score,
    status: game_status(row.period, row.final),
  )
}

@target(erlang)
fn game_status(period: String, final: Int) -> GameStatus {
  case final == 1, period {
    True, _ -> BroadcastFinal
    False, "Scheduled" -> BroadcastScheduled
    False, _ -> BroadcastLive(period)
  }
}
