pub type ServerMsg {
  PublicGamesLoad
}

pub type LoadResult {
  PublicGamesLoaded(games: List(GameSummary))
}

pub type GameStatus {
  PublicGamesScheduled
  PublicGamesLive(period: String)
  PublicGamesFinal
}

pub type Team {
  PublicGamesTeam(code: String, name: String, slug: String)
}

pub type GameSummary {
  PublicGamesGameSummary(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}
