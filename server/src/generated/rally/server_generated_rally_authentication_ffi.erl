%% Generated. Do not edit.
%%
%% Erlang FFI for server authentication helpers.
%% Derived from Rally's server authentication runtime contract.
%% Called by generated/rally/authentication.gleam for PBKDF2 hashing.

-module(server_generated_rally_authentication_ffi).
-export([pbkdf2_hmac_sha256/4]).

pbkdf2_hmac_sha256(Secret, Salt, Iterations, Length) ->
    crypto:pbkdf2_hmac(sha256, Secret, Salt, Iterations, Length).
