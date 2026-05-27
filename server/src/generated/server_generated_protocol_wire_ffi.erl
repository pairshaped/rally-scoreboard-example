%% Generated. Do not edit.
%%
%% Per-type wire-format encode/decode transformers.
%% Derived from the shared API codec graph, mirroring the client
%% codec_ffi.mjs constructor registry one-for-one.
%%
%% Every ToServer, ToClient, and shared API domain constructor is
%% represented. Backend types (e.g. server/admin/model.Model) are
%% intentionally absent: they do not cross the wire.
%%
%% Constructor atoms are unique across the whole shared API graph,
%% so encode/decode functions are identity transforms. The Generator
%% Framework fails generation on collisions instead of adding hidden
%% module paths, hashes, or other disambiguators to the root API wire.

-module(server_generated_protocol_wire_ffi).
-export([
    encode_term/1,
    decode_term/1,
    encode_float/1
]).

encode_float(F) when is_float(F) -> F;
encode_float(N) when is_integer(N) -> N + 0.0.

encode_term(Term) -> encode_term(Term, 0).

encode_term(_Term, Depth) when Depth >= 512 ->
    error({wire_depth_exceeded, Depth});
encode_term(Tuple, Depth) when is_tuple(Tuple), tuple_size(Tuple) > 0 ->
    list_to_tuple([encode_term(E, Depth + 1) || E <- tuple_to_list(Tuple)]);
encode_term(List, Depth) when is_list(List) ->
    [encode_term(X, Depth + 1) || X <- List];
encode_term(Map, Depth) when is_map(Map) ->
    maps:map(fun(_K, V) -> encode_term(V, Depth + 1) end, Map);
encode_term(Other, _Depth) -> Other.

decode_term(Term) -> decode_term(Term, 0).

decode_term(_Term, Depth) when Depth >= 512 ->
    error({wire_depth_exceeded, Depth});
decode_term(Tuple, Depth) when is_tuple(Tuple), tuple_size(Tuple) > 0 ->
    list_to_tuple([decode_term(E, Depth + 1) || E <- tuple_to_list(Tuple)]);
decode_term(List, Depth) when is_list(List) ->
    [decode_term(X, Depth + 1) || X <- List];
decode_term(Map, Depth) when is_map(Map) ->
    maps:map(fun(_K, V) -> decode_term(V, Depth + 1) end, Map);
decode_term(Other, _Depth) -> Other.
