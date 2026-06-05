import gleam/int

/// Rally push payload with the topics that should receive it.
pub type TargetedEvent {
  TargetedEvent(topics: List(String), event: Event)
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
/// app_api builds this from the database after admin mutations, then generated
/// Rally protocol code carries it over the websocket.
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

pub fn all_games_topic() -> String {
  "games"
}

pub fn admin_games_topic() -> String {
  "admin:games"
}

pub fn game_topic(id: Int) -> String {
  "game:" <> int.to_string(id)
}

pub fn team_topic(slug: String) -> String {
  "team:" <> slug
}

pub fn game_updated_targeted_event(game: GameSnapshot) -> TargetedEvent {
  TargetedEvent(
    topics: game_updated_topics(game),
    event: BroadcastGameUpdated(game),
  )
}

pub fn game_updated_topics(game: GameSnapshot) -> List(String) {
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
