%% Generated. Do not edit.
%%
%% Pre-registers all atoms that may appear in client ETF payloads,
%% so binary_to_term([safe]) can decode them without rejecting unknown
%% atoms. Includes framework atoms, handler function names, bare
%% constructor names, and the 10-char hex wire-identity hashes that
%% the per-type transformer functions emit on the wire.
%% Derived from the shared API codec graph.
%%
%% ensure/0 uses persistent_term as a one-shot guard so the
%% binary_to_atom calls only run once per VM lifetime.

-module(server_generated_protocol_atoms_ffi).
-export([ensure/0]).

ensure() ->
    case persistent_term:get({?MODULE, done}, false) of
        true -> nil;
        false -> do_ensure()
    end.

do_ensure() ->
    lists:foreach(fun(B) -> binary_to_atom(B) end, [
        <<"8fd0250257">>,
        <<"correct_result">>,
        <<"create_game">>,
        <<"decode_error">>,
        <<"error">>,
        <<"false">>,
        <<"internal_error">>,
        <<"load_admin_games">>,
        <<"load_game">>,
        <<"load_games">>,
        <<"load_standings">>,
        <<"malformed_request">>,
        <<"mark_final">>,
        <<"model">>,
        <<"nil">>,
        <<"none">>,
        <<"ok">>,
        <<"some">>,
        <<"true">>,
        <<"unknown_function">>,
        <<"update_score">>
    ]),
    persistent_term:put({libero, wire_module}, 'server_generated_protocol_wire_ffi'),
    persistent_term:put({?MODULE, done}, true),
    nil.
