%% Generated. Do not edit.
%%
%% Erlang FFI for server authentication helpers.
%% Derived from the Generator Framework's server authentication runtime contract.
%% Called by generated/runtime/authentication.gleam for PBKDF2 hashing.

-module(server_generated_runtime_authentication_ffi).
-export([pbkdf2_hmac_sha256/4]).

pbkdf2_hmac_sha256(Secret, Salt, Iterations, Length) ->
    crypto:pbkdf2_hmac(sha256, Secret, Salt, Iterations, Length).
