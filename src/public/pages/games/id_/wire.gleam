pub type ServerMsg {
  PublicGameDetailLoad(game_id: Int)
}

pub type LoadResult {
  PublicGameDetailLoaded(game: GameDetail)
}

pub type GameStatus {
  PublicGameDetailScheduled
  PublicGameDetailLive(period: String)
  PublicGameDetailFinal
}

pub type Team {
  PublicGameDetailTeam(code: String, name: String, slug: String)
}

pub type GameDetail {
  PublicGameDetailGameDetail(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}
