@target(erlang)
import admin/pages/games as admin_games_wire
@target(erlang)
import generated/rally/result as transport_result
@target(erlang)
import generated/rally/server_protocol
@target(erlang)
import gleam/bit_array
@target(erlang)
import gleam/list
@target(erlang)
import public/pages/games/id_/wire as public_game_detail_wire
@target(erlang)
import public/pages/games/wire as public_games_wire
@target(erlang)
import public/pages/standings/wire as public_standings_wire
@target(erlang)
import public/pages/teams/slug_/wire as public_team_detail_wire

@target(erlang)
pub type LoadError {
  LoadError(message: String)
}

@target(erlang)
pub fn admin_games_hydration_payload(
  result result: Result(admin_games_wire.LoadResult, List(LoadError)),
) -> String {
  server_protocol.ensure()
  result
  |> map_load_result
  |> server_protocol.encode_admin_games_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
pub fn public_game_detail_hydration_payload(
  result result: Result(public_game_detail_wire.LoadResult, List(LoadError)),
) -> String {
  server_protocol.ensure()
  result
  |> map_load_result
  |> server_protocol.encode_public_game_detail_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
pub fn public_games_hydration_payload(
  result result: Result(public_games_wire.LoadResult, List(LoadError)),
) -> String {
  server_protocol.ensure()
  result
  |> map_load_result
  |> server_protocol.encode_public_games_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
pub fn public_standings_hydration_payload(
  result result: Result(public_standings_wire.LoadResult, List(LoadError)),
) -> String {
  server_protocol.ensure()
  result
  |> map_load_result
  |> server_protocol.encode_public_standings_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
pub fn public_team_detail_hydration_payload(
  result result: Result(public_team_detail_wire.LoadResult, List(LoadError)),
) -> String {
  server_protocol.ensure()
  result
  |> map_load_result
  |> server_protocol.encode_public_team_detail_load_result(request_id: 0)
  |> bit_array.base64_url_encode(False)
}

@target(erlang)
fn map_load_result(
  result: Result(a, List(LoadError)),
) -> Result(a, List(transport_result.ApiLoadError)) {
  case result {
    Ok(value) -> Ok(value)
    Error(errors) ->
      Error(
        list.map(errors, fn(error) {
          let LoadError(message:) = error
          transport_result.ApiLoadError(message:)
        }),
      )
  }
}
