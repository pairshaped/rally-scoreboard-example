%% Generated. Do not edit.
%%
%% Erlang FFI for panic capture and trace ids.
%% Derived from Rally's server trace runtime contract.
%% Called by generated/rally/trace.gleam around generated dispatch calls.

-module(server_generated_rally_trace_ffi).
-export([try_call/1, unique_id/0]).

try_call(F) ->
    try F() of
        Result -> {ok, Result}
    catch
        throw:Reason ->
            Message = io_lib:format(
                "throw: ~p",
                [Reason]
            ),
            {error, erlang:iolist_to_binary(Message)};
        error:Reason:Stacktrace ->
            Message = io_lib:format(
                "~p~nstacktrace: ~p",
                [Reason, Stacktrace]
            ),
            {error, erlang:iolist_to_binary(Message)}
    end.

unique_id() ->
    Int = erlang:unique_integer([positive, monotonic]),
    Time = erlang:system_time(millisecond),
    erlang:iolist_to_binary(io_lib:format("~.16b-~.16b", [Time, Int])).
