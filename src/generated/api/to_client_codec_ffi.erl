-module(to_client_codec_ffi).
-export([ensure/0, encode/1, decode/1]).

ensure() ->
    Atoms = [correct_result, mark_final, update_score, load_admin_games, load_team, load_standings, load_game, load_games, admin_error, result_saved, score_update_saved, game_updated, admin_games_loaded, team_loaded, games_load_failed, power_rankings_loaded, standings_loaded, game_loaded, games_loaded, team_detail, power_ranking_row, standing_row, admin_game_detail, admin_game_summary, game_snapshot, game_detail, public_game_summary, team, final, live, scheduled],
    lists:foreach(fun(Atom) -> erlang:atom_to_binary(Atom, utf8) end, Atoms),
    nil.

encode(Term) ->
    erlang:term_to_binary(Term).

decode(Bin) when is_binary(Bin) ->
    try
        _ = ensure(),
        {ok, erlang:binary_to_term(Bin, [safe])}
    catch
        _:_ -> {error, nil}
    end;
decode(_) ->
    {error, nil}.
