pub type ServerMsg {
  PublicStandingsLoad
}

pub type LoadResult {
  PublicStandingsLoaded(games: List(GameSummary))
}

pub type GameStatus {
  PublicStandingsScheduled
  PublicStandingsLive(period: String)
  PublicStandingsFinal
}

pub type Team {
  PublicStandingsTeam(code: String, name: String, slug: String)
}

pub type GameSummary {
  PublicStandingsGameSummary(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}
