//// Admin games page — view tests.

import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import lustre/element
import shared/admin/pages/games
import shared/api/domain/game.{
  type AdminGameDetail, type AdminGameSummary, AdminGameDetail, AdminGameSummary,
  Final, Live, Scheduled,
}
import shared/api/to_client

fn on_adjust_away(_id, _h, _a, _d) -> Nil {
  Nil
}

fn on_adjust_home(_id, _h, _a, _d) -> Nil {
  Nil
}

fn on_mark_final(_id) -> Nil {
  Nil
}

fn render_view(admin_games: List(AdminGameSummary)) -> String {
  games.view_games(admin_games, on_adjust_away, on_adjust_home, on_mark_final)
  |> element.to_readable_string
}

fn make_game(id: Int, home: String, away: String) -> AdminGameSummary {
  AdminGameSummary(
    id:,
    home_code: home,
    away_code: away,
    home_score: 0,
    away_score: 0,
    status: Scheduled,
    needs_attention: True,
  )
}

pub fn empty_state_renders_placeholder_test() {
  render_view([])
  |> string.contains("No games yet.")
  |> should.be_true
}

pub fn loaded_games_render_team_codes_test() {
  let html =
    render_view([
      make_game(1, "TOR", "NYC"),
      make_game(2, "BOS", "LAK"),
    ])
  html |> string.contains("TOR") |> should.be_true
  html |> string.contains("NYC") |> should.be_true
  html |> string.contains("BOS") |> should.be_true
  html |> string.contains("LAK") |> should.be_true
}

pub fn loaded_games_render_score_controls_test() {
  let html = render_view([make_game(1, "TOR", "NYC")])
  html |> string.contains("+") |> should.be_true
  html |> string.contains("-") |> should.be_true
}

pub fn non_final_game_renders_finalize_button_test() {
  let game = AdminGameSummary(..make_game(1, "TOR", "NYC"), status: Live("3rd"))
  render_view([game])
  |> string.contains("Finalize")
  |> should.be_true
}

pub fn final_game_hides_finalize_button_test() {
  let game = AdminGameSummary(..make_game(1, "TOR", "NYC"), status: Final)
  render_view([game])
  |> string.contains("Finalize")
  |> should.be_false
}

pub fn scheduled_status_renders_badge_test() {
  render_view([make_game(1, "TOR", "NYC")])
  |> string.contains("Scheduled")
  |> should.be_true
}

pub fn final_status_renders_badge_test() {
  let game = AdminGameSummary(..make_game(1, "TOR", "NYC"), status: Final)
  render_view([game])
  |> string.contains("Final")
  |> should.be_true
}

// --- receive mapping tests ---

fn make_admin_detail() -> AdminGameDetail {
  AdminGameDetail(
    id: 1,
    home_code: "TOR",
    away_code: "NYC",
    home_score: 0,
    away_score: 0,
    status: Scheduled,
    period: "",
  )
}

pub fn admin_games_receive_maps_loaded_to_msg_test() {
  let game_list = [make_game(1, "TOR", "NYC")]
  games.receive(to_client.AdminGamesLoaded(games: game_list))
  |> should.equal(Some(games.LoadedGames(game_list)))
}

pub fn admin_games_receive_maps_created_to_msg_test() {
  let detail = make_admin_detail()
  games.receive(to_client.GameCreated(game: detail))
  |> should.equal(Some(games.CreatedGame(detail)))
}

pub fn admin_games_receive_maps_saved_to_msg_test() {
  let detail = make_admin_detail()
  games.receive(to_client.ScoreUpdateSaved(game: detail))
  |> should.equal(Some(games.SavedGame(detail)))
}

pub fn admin_games_receive_maps_result_saved_to_msg_test() {
  let detail = make_admin_detail()
  games.receive(to_client.ResultSaved(game: detail))
  |> should.equal(Some(games.SavedGame(detail)))
}

pub fn admin_games_receive_maps_error_to_failed_test() {
  games.receive(to_client.AdminError(reason: "boom"))
  |> should.equal(Some(games.Failed("boom")))
}

pub fn admin_games_receive_returns_none_for_unknown_test() {
  games.receive(to_client.GamesLoaded(games: []))
  |> should.equal(None)
}
