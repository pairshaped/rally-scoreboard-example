pub type ServerMsg {
  PublicTeamDetailLoad(slug: String)
}

pub type LoadResult {
  PublicTeamDetailLoaded(team: TeamDetail)
}

pub type GameStatus {
  PublicTeamDetailScheduled
  PublicTeamDetailLive(period: String)
  PublicTeamDetailFinal
}

pub type Team {
  PublicTeamDetailTeam(code: String, name: String, slug: String)
}

pub type GameSummary {
  PublicTeamDetailGameSummary(
    id: Int,
    home: Team,
    away: Team,
    home_score: Int,
    away_score: Int,
    status: GameStatus,
  )
}

pub type TeamDetail {
  PublicTeamDetailTeamDetail(
    code: String,
    name: String,
    slug: String,
    wins: Int,
    losses: Int,
    points_for: Int,
    points_against: Int,
    recent_games: List(GameSummary),
  )
}
