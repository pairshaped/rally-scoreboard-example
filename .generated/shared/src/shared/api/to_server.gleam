//// Root API messages sent from browser clients to the server.
////
//// Every constructor is globally unique and may be received by any Mount.
//// Mount-specific dispatch decides which handlers run for each message.

pub type ToServer {
  LoadGames
  LoadGame(game_id: Int)
  LoadStandings
  LoadTeam(slug: String)
  LoadAdminGames
  UpdateScore(game_id: Int, home_score: Int, away_score: Int, period: String)
  MarkFinal(game_id: Int)
  CorrectResult(game_id: Int, home_score: Int, away_score: Int)
}
