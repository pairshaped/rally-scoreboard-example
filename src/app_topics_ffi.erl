-module(app_topics_ffi).
-export([start/0, join/1, broadcast/2]).

start() ->
    case pg:start_link(scoreboard_topics) of
        {ok, _Pid} -> nil;
        {error, {already_started, _Pid}} -> nil
    end.

join(Topic) ->
    pg:join(scoreboard_topics, Topic, self()),
    nil.

broadcast(Topic, Frame) ->
    Members = pg:get_members(scoreboard_topics, Topic),
    lists:foreach(fun(Pid) ->
        Pid ! {scoreboard_frame, Frame}
    end, Members),
    nil.
