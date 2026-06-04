pub type Event {
  BroadcastGameUpdated(game: GameSnapshot)
}

pub type GameStatus {
  BroadcastScheduled
  BroadcastLive(period: String)
  BroadcastFinal
}

pub type Team {
  BroadcastTeam(code: String, name: String, slug: String)
}

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
