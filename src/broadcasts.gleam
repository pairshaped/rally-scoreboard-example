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
